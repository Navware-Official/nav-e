use crate::navigation::domain::ports::Repository;
use crate::infrastructure::persistence::base_repository::{BaseRepository, DatabaseEntity};
use crate::migrations::{get_all_migrations, MigrationManager};
/// SQLite database infrastructure for persistent storage
use anyhow::{Context, Result};
use rusqlite::{Connection, Row};
use std::path::PathBuf;
use std::sync::{Arc, Mutex};

pub struct Database {
    conn: Arc<Mutex<Connection>>,
}

impl Database {
    pub fn new(db_path: PathBuf) -> Result<Self> {
        // Simply try to open the database - the parent directory should already exist on Android
        // Android automatically creates /data/data/<package>/files/ for apps
        let conn = Connection::open(&db_path)
            .with_context(|| format!("Unable to open database file: {}", db_path.display()))?;

        let db = Self {
            conn: Arc::new(Mutex::new(conn)),
        };

        // Run migrations
        let manager = MigrationManager::new(db.get_connection());
        let migrations = get_all_migrations();
        manager
            .migrate(&migrations)
            .context("Failed to run database migrations")?;

        Ok(db)
    }

    pub fn get_connection(&self) -> Arc<Mutex<Connection>> {
        Arc::clone(&self.conn)
    }
}

// Saved Place entity (database representation)
// This is separate from any domain entity and is used only for persistence
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SavedPlaceEntity {
    pub id: Option<i64>,
    pub type_id: Option<i64>,
    pub source: String,
    pub remote_id: Option<String>,
    pub name: String,
    pub address: Option<String>,
    pub lat: f64,
    pub lon: f64,
    pub created_at: i64,
}

impl DatabaseEntity for SavedPlaceEntity {
    type Id = i64;

    fn table_name() -> &'static str {
        "saved_places"
    }

    fn from_row(row: &Row) -> rusqlite::Result<Self> {
        Ok(SavedPlaceEntity {
            id: Some(row.get(0)?),
            type_id: row.get(1)?,
            source: row.get(2)?,
            remote_id: row.get(3)?,
            name: row.get(4)?,
            address: row.get(5)?,
            lat: row.get(6)?,
            lon: row.get(7)?,
            created_at: row.get(8)?,
        })
    }

    fn column_names() -> &'static str {
        "id, type_id, source, remote_id, name, address, lat, lon, created_at"
    }

    fn insert_columns() -> &'static str {
        "type_id, source, remote_id, name, address, lat, lon, created_at"
    }

    fn insert_placeholders() -> &'static str {
        "?, ?, ?, ?, ?, ?, ?, ?"
    }

    fn bind_insert(
        &self,
        stmt: &mut rusqlite::Statement,
        start_idx: usize,
    ) -> rusqlite::Result<()> {
        stmt.raw_bind_parameter(start_idx, self.type_id)?;
        stmt.raw_bind_parameter(start_idx + 1, &self.source)?;
        stmt.raw_bind_parameter(start_idx + 2, self.remote_id.as_ref())?;
        stmt.raw_bind_parameter(start_idx + 3, &self.name)?;
        stmt.raw_bind_parameter(start_idx + 4, self.address.as_ref())?;
        stmt.raw_bind_parameter(start_idx + 5, self.lat)?;
        stmt.raw_bind_parameter(start_idx + 6, self.lon)?;
        stmt.raw_bind_parameter(start_idx + 7, self.created_at)?;
        Ok(())
    }

    fn bind_update(
        &self,
        stmt: &mut rusqlite::Statement,
        start_idx: usize,
    ) -> rusqlite::Result<()> {
        self.bind_insert(stmt, start_idx)
    }
}

// Device entity (database representation)
// This is separate from the domain Device entity and is used only for persistence
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct DeviceEntity {
    pub id: Option<i64>,
    pub remote_id: String,
    pub name: String,
    pub device_type: String,
    pub connection_type: String,
    pub paired: bool,
    pub last_connected: Option<i64>,
    pub firmware_version: Option<String>,
    pub battery_level: Option<i32>,
    pub created_at: i64,
    pub updated_at: i64,
}

impl DatabaseEntity for DeviceEntity {
    type Id = i64;

    fn table_name() -> &'static str {
        "devices"
    }

    fn from_row(row: &Row) -> rusqlite::Result<Self> {
        Ok(DeviceEntity {
            id: Some(row.get(0)?),
            remote_id: row.get(1)?,
            name: row.get(2)?,
            device_type: row.get(3)?,
            connection_type: row.get(4)?,
            paired: row.get::<_, i32>(5)? != 0,
            last_connected: row.get(6)?,
            firmware_version: row.get(7)?,
            battery_level: row.get(8)?,
            created_at: row.get(9)?,
            updated_at: row.get(10)?,
        })
    }

    fn column_names() -> &'static str {
        "id, remote_id, name, device_type, connection_type, paired, last_connected, firmware_version, battery_level, created_at, updated_at"
    }

    fn insert_columns() -> &'static str {
        "remote_id, name, device_type, connection_type, paired, last_connected, firmware_version, battery_level, created_at, updated_at"
    }

    fn insert_placeholders() -> &'static str {
        "?, ?, ?, ?, ?, ?, ?, ?, ?, ?"
    }

    fn bind_insert(
        &self,
        stmt: &mut rusqlite::Statement,
        start_idx: usize,
    ) -> rusqlite::Result<()> {
        stmt.raw_bind_parameter(start_idx, &self.remote_id)?;
        stmt.raw_bind_parameter(start_idx + 1, &self.name)?;
        stmt.raw_bind_parameter(start_idx + 2, &self.device_type)?;
        stmt.raw_bind_parameter(start_idx + 3, &self.connection_type)?;
        stmt.raw_bind_parameter(start_idx + 4, if self.paired { 1 } else { 0 })?;
        stmt.raw_bind_parameter(start_idx + 5, self.last_connected)?;
        stmt.raw_bind_parameter(start_idx + 6, self.firmware_version.as_ref())?;
        stmt.raw_bind_parameter(start_idx + 7, self.battery_level)?;
        stmt.raw_bind_parameter(start_idx + 8, self.created_at)?;
        stmt.raw_bind_parameter(start_idx + 9, self.updated_at)?;
        Ok(())
    }

    fn bind_update(
        &self,
        stmt: &mut rusqlite::Statement,
        start_idx: usize,
    ) -> rusqlite::Result<()> {
        self.bind_insert(stmt, start_idx)
    }
}

// Saved Places Repository
pub type SavedPlacesRepository = BaseRepository<SavedPlaceEntity, i64>;

// Trip entity (database representation) for completed route history
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct TripEntity {
    pub id: Option<i64>,
    pub distance_m: f64,
    pub duration_seconds: i64,
    pub started_at: i64,
    pub completed_at: i64,
    pub status: String,
    pub destination_label: Option<String>,
    pub route_id: Option<String>,
    pub polyline_encoded: Option<String>,
    pub created_at: i64,
}

impl DatabaseEntity for TripEntity {
    type Id = i64;

    fn table_name() -> &'static str {
        "trips"
    }

    fn from_row(row: &Row) -> rusqlite::Result<Self> {
        Ok(TripEntity {
            id: Some(row.get(0)?),
            distance_m: row.get(1)?,
            duration_seconds: row.get(2)?,
            started_at: row.get(3)?,
            completed_at: row.get(4)?,
            status: row.get(5)?,
            destination_label: row.get(6)?,
            route_id: row.get(7)?,
            polyline_encoded: row.get(8)?,
            created_at: row.get(9)?,
        })
    }

    fn column_names() -> &'static str {
        "id, distance_m, duration_seconds, started_at, completed_at, status, destination_label, route_id, polyline_encoded, created_at"
    }

    fn insert_columns() -> &'static str {
        "distance_m, duration_seconds, started_at, completed_at, status, destination_label, route_id, polyline_encoded, created_at"
    }

    fn insert_placeholders() -> &'static str {
        "?, ?, ?, ?, ?, ?, ?, ?, ?"
    }

    fn bind_insert(
        &self,
        stmt: &mut rusqlite::Statement,
        start_idx: usize,
    ) -> rusqlite::Result<()> {
        stmt.raw_bind_parameter(start_idx, self.distance_m)?;
        stmt.raw_bind_parameter(start_idx + 1, self.duration_seconds)?;
        stmt.raw_bind_parameter(start_idx + 2, self.started_at)?;
        stmt.raw_bind_parameter(start_idx + 3, self.completed_at)?;
        stmt.raw_bind_parameter(start_idx + 4, &self.status)?;
        stmt.raw_bind_parameter(start_idx + 5, self.destination_label.as_ref())?;
        stmt.raw_bind_parameter(start_idx + 6, self.route_id.as_ref())?;
        stmt.raw_bind_parameter(start_idx + 7, self.polyline_encoded.as_ref())?;
        stmt.raw_bind_parameter(start_idx + 8, self.created_at)?;
        Ok(())
    }

    fn bind_update(
        &self,
        stmt: &mut rusqlite::Statement,
        start_idx: usize,
    ) -> rusqlite::Result<()> {
        self.bind_insert(stmt, start_idx)
    }
}

// Trips Repository
pub type TripsRepository = BaseRepository<TripEntity, i64>;

// Saved Route entity (database representation) for imported/saved routes
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SavedRouteEntity {
    pub id: Option<i64>,
    pub name: String,
    pub route_json: String,
    pub source: String,
    pub created_at: i64,
}

impl DatabaseEntity for SavedRouteEntity {
    type Id = i64;

    fn table_name() -> &'static str {
        "saved_routes"
    }

    fn from_row(row: &Row) -> rusqlite::Result<Self> {
        Ok(SavedRouteEntity {
            id: Some(row.get(0)?),
            name: row.get(1)?,
            route_json: row.get(2)?,
            source: row.get(3)?,
            created_at: row.get(4)?,
        })
    }

    fn column_names() -> &'static str {
        "id, name, route_json, source, created_at"
    }

    fn insert_columns() -> &'static str {
        "name, route_json, source, created_at"
    }

    fn insert_placeholders() -> &'static str {
        "?, ?, ?, ?"
    }

    fn bind_insert(
        &self,
        stmt: &mut rusqlite::Statement,
        start_idx: usize,
    ) -> rusqlite::Result<()> {
        stmt.raw_bind_parameter(start_idx, &self.name)?;
        stmt.raw_bind_parameter(start_idx + 1, &self.route_json)?;
        stmt.raw_bind_parameter(start_idx + 2, &self.source)?;
        stmt.raw_bind_parameter(start_idx + 3, self.created_at)?;
        Ok(())
    }

    fn bind_update(
        &self,
        stmt: &mut rusqlite::Statement,
        start_idx: usize,
    ) -> rusqlite::Result<()> {
        self.bind_insert(stmt, start_idx)
    }
}

// Saved Routes Repository
pub type SavedRoutesRepository = BaseRepository<SavedRouteEntity, i64>;

// Device Repository
#[derive(Clone)]
pub struct DeviceRepository {
    base: BaseRepository<DeviceEntity, i64>,
}

impl DeviceRepository {
    pub fn new(db: Arc<Mutex<Connection>>) -> Self {
        Self {
            base: BaseRepository::new(db),
        }
    }

    // Specialized method: query by remote_id
    pub fn get_by_remote_id(&self, remote_id: &str) -> Result<Option<DeviceEntity>> {
        let conn = self.base.db().lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, remote_id, name, device_type, connection_type, paired, 
                    last_connected, firmware_version, battery_level, created_at, updated_at 
             FROM devices WHERE remote_id = ?",
        )?;

        let result = stmt.query_row([remote_id], DeviceEntity::from_row);

        match result {
            Ok(device) => Ok(Some(device)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    // Specialized method: check existence by remote_id
    pub fn exists_by_remote_id(&self, remote_id: &str) -> Result<bool> {
        let conn = self.base.db().lock().unwrap();
        let count: i64 = conn.query_row(
            "SELECT COUNT(*) FROM devices WHERE remote_id = ?",
            [remote_id],
            |row| row.get(0),
        )?;
        Ok(count > 0)
    }
}

// Delegate to base repository implementation
impl Repository<DeviceEntity, i64> for DeviceRepository {
    fn get_all(&self) -> Result<Vec<DeviceEntity>> {
        self.base.get_all()
    }

    fn get_by_id(&self, id: i64) -> Result<Option<DeviceEntity>> {
        self.base.get_by_id(id)
    }

    fn insert(&self, entity: DeviceEntity) -> Result<i64> {
        self.base.insert(entity)
    }

    fn update(&self, id: i64, entity: DeviceEntity) -> Result<()> {
        self.base.update(id, entity)
    }

    fn delete(&self, id: i64) -> Result<()> {
        self.base.delete(id)
    }
}

// ============================================================================
// Offline region entity and repository (String id, custom impl)
// ============================================================================

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OfflineRegionEntity {
    pub id: String,
    pub name: String,
    pub north: f64,
    pub south: f64,
    pub east: f64,
    pub west: f64,
    pub min_zoom: i32,
    pub max_zoom: i32,
    pub relative_path: String,
    pub size_bytes: i64,
    pub created_at: i64,
}

#[derive(Clone)]
pub struct OfflineRegionsRepository {
    db: Arc<Mutex<Connection>>,
    storage_base_path: std::path::PathBuf,
}

impl OfflineRegionsRepository {
    pub fn new(db: Arc<Mutex<Connection>>, storage_base_path: std::path::PathBuf) -> Self {
        Self {
            db,
            storage_base_path,
        }
    }

    pub fn get_all(&self) -> Result<Vec<OfflineRegionEntity>> {
        let conn = self.db.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, name, north, south, east, west, min_zoom, max_zoom, relative_path, size_bytes, created_at
             FROM offline_regions ORDER BY created_at DESC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(OfflineRegionEntity {
                id: row.get(0)?,
                name: row.get(1)?,
                north: row.get(2)?,
                south: row.get(3)?,
                east: row.get(4)?,
                west: row.get(5)?,
                min_zoom: row.get(6)?,
                max_zoom: row.get(7)?,
                relative_path: row.get(8)?,
                size_bytes: row.get(9)?,
                created_at: row.get(10)?,
            })
        })?;
        rows.collect::<rusqlite::Result<Vec<_>>>()
            .map_err(Into::into)
    }

    pub fn get_by_id(&self, id: &str) -> Result<Option<OfflineRegionEntity>> {
        let conn = self.db.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, name, north, south, east, west, min_zoom, max_zoom, relative_path, size_bytes, created_at
             FROM offline_regions WHERE id = ?",
        )?;
        let result = stmt.query_row([id], |row| {
            Ok(OfflineRegionEntity {
                id: row.get(0)?,
                name: row.get(1)?,
                north: row.get(2)?,
                south: row.get(3)?,
                east: row.get(4)?,
                west: row.get(5)?,
                min_zoom: row.get(6)?,
                max_zoom: row.get(7)?,
                relative_path: row.get(8)?,
                size_bytes: row.get(9)?,
                created_at: row.get(10)?,
            })
        });
        match result {
            Ok(e) => Ok(Some(e)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    pub fn insert(&self, entity: &OfflineRegionEntity) -> Result<()> {
        let conn = self.db.lock().unwrap();
        conn.execute(
            "INSERT INTO offline_regions (id, name, north, south, east, west, min_zoom, max_zoom, relative_path, size_bytes, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)",
            rusqlite::params![
                entity.id,
                entity.name,
                entity.north,
                entity.south,
                entity.east,
                entity.west,
                entity.min_zoom,
                entity.max_zoom,
                entity.relative_path,
                entity.size_bytes,
                entity.created_at,
            ],
        )?;
        Ok(())
    }

    pub fn delete(&self, id: &str) -> Result<()> {
        let conn = self.db.lock().unwrap();
        conn.execute("DELETE FROM offline_regions WHERE id = ?", [id])?;
        Ok(())
    }

    pub fn get_region_for_viewport(
        &self,
        north: f64,
        south: f64,
        east: f64,
        west: f64,
    ) -> Result<Option<OfflineRegionEntity>> {
        let regions = self.get_all()?;
        for r in regions {
            if r.intersects_bbox(north, south, east, west) {
                return Ok(Some(r));
            }
        }
        Ok(None)
    }

    pub fn get_storage_path(&self) -> Result<String> {
        Ok(self.storage_base_path.to_string_lossy().into_owned())
    }
}

impl OfflineRegionEntity {
    pub fn intersects_bbox(&self, n: f64, s: f64, e: f64, w: f64) -> bool {
        !(n < self.south || s > self.north || e < self.west || w > self.east)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::migrations::{get_all_migrations, MigrationManager};
    use rusqlite::Connection;

    fn setup_db() -> Arc<Mutex<Connection>> {
        let conn = Arc::new(Mutex::new(Connection::open_in_memory().unwrap()));
        let mgr = MigrationManager::new(Arc::clone(&conn));
        mgr.migrate(&get_all_migrations()).unwrap();
        conn
    }

    // ── DeviceRepository ─────────────────────────────────────────────────────

    fn make_device(remote_id: &str) -> DeviceEntity {
        let now = chrono::Utc::now().timestamp_millis();
        DeviceEntity {
            id: None,
            remote_id: remote_id.to_string(),
            name: "Test Watch".to_string(),
            device_type: "WearOs".to_string(),
            connection_type: "BLE".to_string(),
            paired: true,
            last_connected: None,
            firmware_version: None,
            battery_level: None,
            created_at: now,
            updated_at: now,
        }
    }

    #[test]
    fn device_repo_get_by_remote_id_found() {
        let conn = setup_db();
        let repo = DeviceRepository::new(conn);
        repo.insert(make_device("dev-abc")).unwrap();
        let found = repo.get_by_remote_id("dev-abc").unwrap();
        assert!(found.is_some());
        assert_eq!(found.unwrap().remote_id, "dev-abc");
    }

    #[test]
    fn device_repo_get_by_remote_id_not_found() {
        let conn = setup_db();
        let repo = DeviceRepository::new(conn);
        assert!(repo.get_by_remote_id("nonexistent").unwrap().is_none());
    }

    #[test]
    fn device_repo_exists_by_remote_id() {
        let conn = setup_db();
        let repo = DeviceRepository::new(conn);
        assert!(!repo.exists_by_remote_id("dev-xyz").unwrap());
        repo.insert(make_device("dev-xyz")).unwrap();
        assert!(repo.exists_by_remote_id("dev-xyz").unwrap());
    }

    // ── OfflineRegionEntity::intersects_bbox ─────────────────────────────────

    fn make_region(n: f64, s: f64, e: f64, w: f64) -> OfflineRegionEntity {
        OfflineRegionEntity {
            id: "r1".to_string(),
            name: "Test Region".to_string(),
            north: n,
            south: s,
            east: e,
            west: w,
            min_zoom: 8,
            max_zoom: 14,
            relative_path: "r1.mbtiles".to_string(),
            size_bytes: 0,
            created_at: 0,
        }
    }

    #[test]
    fn offline_region_intersects_overlapping_viewport() {
        // Region covers 48-52°N, -2-2°E
        let region = make_region(52.0, 48.0, 2.0, -2.0);
        // Viewport: 50-55°N, 0-5°E — overlaps
        assert!(region.intersects_bbox(55.0, 50.0, 5.0, 0.0));
    }

    #[test]
    fn offline_region_does_not_intersect_disjoint_north() {
        let region = make_region(52.0, 48.0, 2.0, -2.0);
        // Viewport entirely north of region
        assert!(!region.intersects_bbox(60.0, 55.0, 2.0, -2.0));
    }

    #[test]
    fn offline_region_does_not_intersect_disjoint_south() {
        let region = make_region(52.0, 48.0, 2.0, -2.0);
        assert!(!region.intersects_bbox(46.0, 40.0, 2.0, -2.0));
    }

    #[test]
    fn offline_region_does_not_intersect_disjoint_east() {
        let region = make_region(52.0, 48.0, 2.0, -2.0);
        assert!(!region.intersects_bbox(52.0, 48.0, 10.0, 5.0));
    }

    #[test]
    fn offline_region_does_not_intersect_disjoint_west() {
        let region = make_region(52.0, 48.0, 2.0, -2.0);
        assert!(!region.intersects_bbox(52.0, 48.0, -5.0, -10.0));
    }

    #[test]
    fn offline_region_intersects_when_viewport_contained_within() {
        let region = make_region(60.0, 40.0, 20.0, -20.0);
        // Viewport fully inside region
        assert!(region.intersects_bbox(52.0, 48.0, 2.0, -2.0));
    }

    // ── OfflineRegionsRepository CRUD ────────────────────────────────────────

    fn make_offline_region_entity(id: &str) -> OfflineRegionEntity {
        OfflineRegionEntity {
            id: id.to_string(),
            name: "Region".to_string(),
            north: 52.0,
            south: 48.0,
            east: 2.0,
            west: -2.0,
            min_zoom: 8,
            max_zoom: 14,
            relative_path: format!("{id}.mbtiles"),
            size_bytes: 1024,
            created_at: chrono::Utc::now().timestamp(),
        }
    }

    #[test]
    fn offline_regions_repo_insert_and_get_all() {
        let conn = setup_db();
        let storage = std::path::PathBuf::from("/tmp");
        let repo = OfflineRegionsRepository::new(conn, storage);
        repo.insert(&make_offline_region_entity("region-1"))
            .unwrap();
        repo.insert(&make_offline_region_entity("region-2"))
            .unwrap();
        let all = repo.get_all().unwrap();
        assert_eq!(all.len(), 2);
    }

    #[test]
    fn offline_regions_repo_get_by_id() {
        let conn = setup_db();
        let repo = OfflineRegionsRepository::new(conn, std::path::PathBuf::from("/tmp"));
        repo.insert(&make_offline_region_entity("region-abc"))
            .unwrap();
        let found = repo.get_by_id("region-abc").unwrap();
        assert!(found.is_some());
        assert_eq!(found.unwrap().id, "region-abc");
    }

    #[test]
    fn offline_regions_repo_delete() {
        let conn = setup_db();
        let repo = OfflineRegionsRepository::new(conn, std::path::PathBuf::from("/tmp"));
        repo.insert(&make_offline_region_entity("region-del"))
            .unwrap();
        repo.delete("region-del").unwrap();
        assert!(repo.get_by_id("region-del").unwrap().is_none());
    }

    // ── SavedPlacesRepository ─────────────────────────────────────────────────

    #[test]
    fn saved_places_repo_insert_and_retrieve() {
        let conn = setup_db();
        let repo = SavedPlacesRepository::new(conn);
        let place = SavedPlaceEntity {
            id: None,
            type_id: None,
            source: "manual".to_string(),
            remote_id: None,
            name: "Home".to_string(),
            address: Some("1 Main St".to_string()),
            lat: 51.5,
            lon: -0.12,
            created_at: chrono::Utc::now().timestamp_millis(),
        };
        let id = repo.insert(place).unwrap();
        let found = repo.get_by_id(id).unwrap();
        assert!(found.is_some());
        assert_eq!(found.unwrap().name, "Home");
    }

    #[test]
    fn saved_places_repo_delete() {
        let conn = setup_db();
        let repo = SavedPlacesRepository::new(conn);
        let place = SavedPlaceEntity {
            id: None,
            type_id: None,
            source: "manual".to_string(),
            remote_id: None,
            name: "Work".to_string(),
            address: None,
            lat: 51.5,
            lon: -0.12,
            created_at: chrono::Utc::now().timestamp_millis(),
        };
        let id = repo.insert(place).unwrap();
        repo.delete(id).unwrap();
        assert!(repo.get_by_id(id).unwrap().is_none());
    }
}
