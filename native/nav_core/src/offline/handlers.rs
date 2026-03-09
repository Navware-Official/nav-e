// Offline regions application service — handles all offline map region use cases.
use anyhow::{Context, Result};
use std::fs;
use std::path::Path;

use crate::infrastructure::database::{OfflineRegionEntity, OfflineRegionsRepository};
use crate::offline::commands::*;
use crate::offline::queries::*;

const DEFAULT_TILE_URL: &str = "https://demotiles.maplibre.org/tiles/{z}/{x}/{y}.pbf";

/// Handles all use cases for offline region management, including tile downloads.
///
/// Constructed once in [`AppContext`] and held for the lifetime of the app.
pub struct OfflineHandlers {
    offline_regions_repo: OfflineRegionsRepository,
}

impl OfflineHandlers {
    pub fn new(offline_regions_repo: OfflineRegionsRepository) -> Self {
        Self {
            offline_regions_repo,
        }
    }

    pub fn get_all_offline_regions(
        &self,
        _: GetAllOfflineRegionsQuery,
    ) -> Result<Vec<OfflineRegionEntity>> {
        self.offline_regions_repo.get_all()
    }

    pub fn get_offline_region_by_id(
        &self,
        q: GetOfflineRegionByIdQuery,
    ) -> Result<Option<OfflineRegionEntity>> {
        self.offline_regions_repo.get_by_id(&q.id)
    }

    pub fn get_offline_region_for_viewport(
        &self,
        q: GetOfflineRegionForViewportQuery,
    ) -> Result<Option<OfflineRegionEntity>> {
        self.offline_regions_repo
            .get_region_for_viewport(q.north, q.south, q.east, q.west)
    }

    pub fn get_storage_path(&self, _: GetStoragePathQuery) -> Result<String> {
        self.offline_regions_repo.get_storage_path()
    }

    /// Return tile coordinates available for a region by walking its storage directory.
    pub fn get_tile_list(
        &self,
        q: GetOfflineRegionTileListQuery,
    ) -> Result<Vec<serde_json::Value>> {
        let region = self
            .offline_regions_repo
            .get_by_id(&q.region_id)?
            .context("Region not found")?;
        let storage = self.offline_regions_repo.get_storage_path()?;
        let region_dir = Path::new(&storage).join(&region.relative_path);
        let mut tiles = Vec::new();

        for z_entry in fs::read_dir(&region_dir).context("Read region directory")? {
            let z_entry = z_entry?;
            let z: i32 = z_entry.file_name().to_string_lossy().parse().unwrap_or(-1);
            if z < 0 {
                continue;
            }
            for x_entry in fs::read_dir(z_entry.path()).context("Read z directory")? {
                let x_entry = x_entry?;
                let x: i32 = x_entry.file_name().to_string_lossy().parse().unwrap_or(-1);
                if x < 0 {
                    continue;
                }
                for y_entry in fs::read_dir(x_entry.path()).context("Read x directory")? {
                    let y_entry = y_entry?;
                    let name = y_entry.file_name();
                    let name_str = name.to_string_lossy();
                    if name_str.ends_with(".pbf") {
                        if let Ok(y) = name_str.trim_end_matches(".pbf").parse::<i32>() {
                            tiles.push(serde_json::json!({"z": z, "x": x, "y": y}));
                        }
                    }
                }
            }
        }
        Ok(tiles)
    }

    /// Read raw `.pbf` bytes for a specific tile.
    pub fn get_tile_bytes(&self, q: GetOfflineRegionTileBytesQuery) -> Result<Vec<u8>> {
        let region = self
            .offline_regions_repo
            .get_by_id(&q.region_id)?
            .context("Region not found")?;
        let storage = self.offline_regions_repo.get_storage_path()?;
        let tile_path = Path::new(&storage)
            .join(&region.relative_path)
            .join(q.z.to_string())
            .join(q.x.to_string())
            .join(format!("{}.pbf", q.y));
        fs::read(&tile_path).context("Read tile file")
    }

    /// Delete a region from the database and remove its tile directory.
    pub fn delete_offline_region(&self, cmd: DeleteOfflineRegionCommand) -> Result<()> {
        let region = self.offline_regions_repo.get_by_id(&cmd.id)?;
        self.offline_regions_repo.delete(&cmd.id)?;
        if let Some(r) = region {
            let storage = self.offline_regions_repo.get_storage_path()?;
            let dir = Path::new(&storage).join(&r.relative_path);
            let _ = fs::remove_dir_all(&dir);
        }
        Ok(())
    }

    /// Download tiles for a bounding box, write to disk, and register the region in the DB.
    /// Returns the persisted region as JSON.
    pub fn download_offline_region(&self, cmd: DownloadOfflineRegionCommand) -> Result<String> {
        let template = cmd
            .tile_url_template
            .unwrap_or_else(|| DEFAULT_TILE_URL.to_string());

        let storage_path = self.offline_regions_repo.get_storage_path()?;
        let id = uuid::Uuid::new_v4().to_string();
        let relative_path = format!("region_{}", id);
        let region_dir = Path::new(&storage_path).join(&relative_path);
        fs::create_dir_all(&region_dir).context("Create offline region directory")?;

        let client = reqwest::blocking::Client::builder()
            .user_agent("nav-e/1.0 (offline maps)")
            .build()
            .context("Build HTTP client")?;

        let mut size_bytes: i64 = 0;
        for z in cmd.min_zoom..=cmd.max_zoom {
            let (tl_x, tl_y) = tile_xy(cmd.north, cmd.west, z);
            let (br_x, br_y) = tile_xy(cmd.south, cmd.east, z);
            let (min_x, max_x) = (tl_x.min(br_x), tl_x.max(br_x));
            let (min_y, max_y) = (tl_y.min(br_y), tl_y.max(br_y));

            for x in min_x..=max_x {
                for y in min_y..=max_y {
                    let url = template
                        .replace("{z}", &z.to_string())
                        .replace("{x}", &x.to_string())
                        .replace("{y}", &y.to_string());
                    if let Ok(resp) = client.get(&url).send() {
                        if resp.status().is_success() {
                            if let Ok(bytes) = resp.bytes() {
                                if !bytes.is_empty() {
                                    let tile_path = region_dir
                                        .join(z.to_string())
                                        .join(x.to_string())
                                        .join(format!("{}.pbf", y));
                                    if let Some(parent) = tile_path.parent() {
                                        let _ = fs::create_dir_all(parent);
                                    }
                                    if fs::write(&tile_path, &*bytes).is_ok() {
                                        size_bytes += bytes.len() as i64;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        let entity = OfflineRegionEntity {
            id: id.clone(),
            name: cmd.name,
            north: cmd.north,
            south: cmd.south,
            east: cmd.east,
            west: cmd.west,
            min_zoom: cmd.min_zoom,
            max_zoom: cmd.max_zoom,
            relative_path,
            size_bytes,
            created_at: chrono::Utc::now().timestamp_millis(),
        };
        self.offline_regions_repo.insert(&entity)?;
        serde_json::to_string(&entity).map_err(Into::into)
    }
}

/// Convert lat/lon to Web Mercator tile XY at zoom level `z`.
fn tile_xy(lat: f64, lon: f64, z: i32) -> (i32, i32) {
    let lat_rad = lat.to_radians();
    let n = 2f64.powi(z);
    let x = ((lon + 180.0) / 360.0 * n).floor() as i32;
    let y = ((1.0 - (lat_rad.tan() + (1.0 / lat_rad.cos())).ln() / std::f64::consts::PI) / 2.0 * n)
        .floor() as i32;
    (x, y)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::migrations::{get_all_migrations, MigrationManager};
    use rusqlite::Connection;
    use std::sync::{Arc, Mutex};

    fn setup_db() -> Arc<Mutex<Connection>> {
        let conn = Arc::new(Mutex::new(Connection::open_in_memory().unwrap()));
        MigrationManager::new(Arc::clone(&conn))
            .migrate(&get_all_migrations())
            .unwrap();
        conn
    }

    fn handlers(db: Arc<Mutex<Connection>>) -> OfflineHandlers {
        let storage = std::path::PathBuf::from("/tmp/nav_e_test_offline");
        OfflineHandlers::new(OfflineRegionsRepository::new(db, storage))
    }

    fn insert_region(h: &OfflineHandlers, id: &str) {
        let entity = OfflineRegionEntity {
            id: id.to_string(),
            name: "Test Region".into(),
            north: 52.0,
            south: 48.0,
            east: 2.0,
            west: -2.0,
            min_zoom: 8,
            max_zoom: 10,
            relative_path: format!("region_{}", id),
            size_bytes: 1024,
            created_at: chrono::Utc::now().timestamp_millis(),
        };
        h.offline_regions_repo.insert(&entity).unwrap();
    }

    #[test]
    fn get_all_offline_regions_returns_all() {
        let h = handlers(setup_db());
        insert_region(&h, "r1");
        insert_region(&h, "r2");
        assert_eq!(
            h.get_all_offline_regions(GetAllOfflineRegionsQuery)
                .unwrap()
                .len(),
            2
        );
    }

    #[test]
    fn get_offline_region_by_id_found() {
        let h = handlers(setup_db());
        insert_region(&h, "r-abc");
        let region = h
            .get_offline_region_by_id(GetOfflineRegionByIdQuery { id: "r-abc".into() })
            .unwrap()
            .unwrap();
        assert_eq!(region.id, "r-abc");
    }

    #[test]
    fn get_offline_region_by_id_not_found() {
        let h = handlers(setup_db());
        assert!(h
            .get_offline_region_by_id(GetOfflineRegionByIdQuery { id: "nope".into() })
            .unwrap()
            .is_none());
    }

    #[test]
    fn get_offline_region_for_viewport_intersects() {
        let h = handlers(setup_db());
        insert_region(&h, "v1"); // covers 48–52°N, -2–2°E
        let found = h
            .get_offline_region_for_viewport(GetOfflineRegionForViewportQuery {
                north: 53.0,
                south: 50.0,
                east: 3.0,
                west: 0.0,
            })
            .unwrap();
        assert!(found.is_some());
    }

    #[test]
    fn get_offline_region_for_viewport_no_match() {
        let h = handlers(setup_db());
        insert_region(&h, "v2"); // covers 48–52°N, -2–2°E
        let found = h
            .get_offline_region_for_viewport(GetOfflineRegionForViewportQuery {
                north: 60.0,
                south: 55.0,
                east: 30.0,
                west: 20.0,
            })
            .unwrap();
        assert!(found.is_none());
    }

    #[test]
    fn delete_offline_region_removes_from_db() {
        let h = handlers(setup_db());
        insert_region(&h, "del-1");
        h.delete_offline_region(DeleteOfflineRegionCommand { id: "del-1".into() })
            .unwrap();
        assert!(h
            .get_offline_region_by_id(GetOfflineRegionByIdQuery { id: "del-1".into() })
            .unwrap()
            .is_none());
    }

    #[test]
    fn tile_xy_known_values() {
        // London at z=10: x=511, y=340 (standard Web Mercator)
        let (x, y) = tile_xy(51.5, -0.12, 10);
        assert_eq!(x, 511);
        assert_eq!(y, 340);
    }
}
