//! Offline regions application service — handles all offline map region use cases.
use anyhow::{anyhow, Context, Result};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::Arc;

use pmtiles::{AsyncPmTilesReader, MmapBackend, TileCoord};
use tokio::sync::RwLock;

use crate::infrastructure::database::{OfflineRegionEntity, OfflineRegionsRepository};
use crate::offline::commands::*;
use crate::offline::domain::ports::TileArchiveService;
use crate::offline::domain::value_objects::RegionMetadata;
use crate::offline::queries::*;

type ReaderHandle = Arc<AsyncPmTilesReader<MmapBackend>>;

/// Handles all use cases for offline region management.
///
/// Constructed once in [`AppContainer`] and held for the lifetime of the app.
pub struct OfflineHandlers {
    offline_regions_repo: OfflineRegionsRepository,
    tile_archive: Arc<dyn TileArchiveService>,
    /// Cache of opened PMTiles readers, keyed by local region id (`OfflineRegionEntity::id`).
    /// Open is expensive (mmap + header parse) so we keep readers warm for the app's lifetime.
    readers: RwLock<HashMap<String, ReaderHandle>>,
}

impl OfflineHandlers {
    pub fn new(
        offline_regions_repo: OfflineRegionsRepository,
        tile_archive: Arc<dyn TileArchiveService>,
    ) -> Self {
        Self {
            offline_regions_repo,
            tile_archive,
            readers: RwLock::new(HashMap::new()),
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

    /// Return the bounds + zoom range from the region's PMTiles header.
    pub async fn get_tile_list(
        &self,
        q: GetOfflineRegionTileListQuery,
    ) -> Result<serde_json::Value> {
        let region = self
            .offline_regions_repo
            .get_by_id(&q.region_id)?
            .context("Region not found")?;
        let reader = self.reader_for(&region).await?;
        let header = reader.get_header();
        Ok(serde_json::json!({
            "minZoom": header.min_zoom,
            "maxZoom": header.max_zoom,
            "bounds": {
                "north": header.max_latitude,
                "south": header.min_latitude,
                "east": header.max_longitude,
                "west": header.min_longitude,
            },
        }))
    }

    /// Read a tile from the region's PMTiles archive. Returns the raw (decompressed)
    /// vector-tile bytes that MapLibre expects.
    pub async fn get_tile_bytes(&self, q: GetOfflineRegionTileBytesQuery) -> Result<Vec<u8>> {
        let region = self
            .offline_regions_repo
            .get_by_id(&q.region_id)?
            .context("Region not found")?;
        let reader = self.reader_for(&region).await?;
        let coord = TileCoord::new(q.z as u8, q.x as u32, q.y as u32)
            .with_context(|| format!("Invalid tile coordinate {}/{}/{}", q.z, q.x, q.y))?;
        let bytes = reader
            .get_tile_decompressed(coord)
            .await
            .context("Read tile from PMTiles archive")?
            .ok_or_else(|| anyhow!("Tile {}/{}/{} not present", q.z, q.x, q.y))?;
        Ok(bytes.to_vec())
    }

    /// Delete a region: drop its cached reader and remove the `.pmtiles` file.
    pub async fn delete_offline_region(&self, cmd: DeleteOfflineRegionCommand) -> Result<()> {
        let region = self.offline_regions_repo.get_by_id(&cmd.id)?;
        self.offline_regions_repo.delete(&cmd.id)?;
        // Drop the cached reader (and the underlying mmap/file handle) so the unlink succeeds.
        self.readers.write().await.remove(&cmd.id);
        if let Some(r) = region {
            let path = self.archive_path(&r);
            let _ = std::fs::remove_file(&path);
        }
        Ok(())
    }

    /// Fetch the gateway region catalog.
    pub async fn list_available_regions(
        &self,
        _: ListAvailableRegionsQuery,
    ) -> Result<Vec<RegionMetadata>> {
        self.tile_archive.list_regions().await
    }

    /// Download a region's PMTiles archive and register it in the DB.
    pub async fn download_offline_region(
        &self,
        cmd: DownloadOfflineRegionCommand,
    ) -> Result<OfflineRegionEntity> {
        let storage_path = self.offline_regions_repo.get_storage_path()?;
        let storage_dir = PathBuf::from(&storage_path);
        std::fs::create_dir_all(&storage_dir).context("Create offline regions storage dir")?;

        let local_id = uuid::Uuid::new_v4().to_string();
        let relative_path = format!("region_{}.pmtiles", local_id);
        let dest_path = storage_dir.join(&relative_path);

        let downloaded = self
            .tile_archive
            .download_region(&cmd.region_id, &dest_path)
            .await?;

        // Read header to capture the actual zoom range stored in the archive.
        let reader = AsyncPmTilesReader::new_with_path(&dest_path)
            .await
            .context("Open downloaded PMTiles archive")?;
        let header = reader.get_header();
        let min_zoom = header.min_zoom as i32;
        let max_zoom = header.max_zoom as i32;

        // Stash the warm reader so the first map load doesn't pay the open cost again.
        self.readers
            .write()
            .await
            .insert(local_id.clone(), Arc::new(reader));

        let entity = OfflineRegionEntity {
            id: local_id,
            region_id: downloaded.region_id,
            name: downloaded.name,
            north: downloaded.bounds.north,
            south: downloaded.bounds.south,
            east: downloaded.bounds.east,
            west: downloaded.bounds.west,
            min_zoom,
            max_zoom,
            relative_path,
            size_bytes: downloaded.size_bytes as i64,
            created_at: chrono::Utc::now().timestamp_millis(),
        };
        self.offline_regions_repo.insert(&entity)?;
        Ok(entity)
    }

    fn archive_path(&self, region: &OfflineRegionEntity) -> PathBuf {
        let storage = self
            .offline_regions_repo
            .get_storage_path()
            .unwrap_or_default();
        Path::new(&storage).join(&region.relative_path)
    }

    /// Get (or open) the cached PMTiles reader for `region`.
    async fn reader_for(&self, region: &OfflineRegionEntity) -> Result<ReaderHandle> {
        if let Some(r) = self.readers.read().await.get(&region.id) {
            return Ok(Arc::clone(r));
        }
        // Cold path — open the archive and insert. Two concurrent callers may both
        // open the same file; that's fine (mmap is cheap, second insert wins) and
        // dramatically simpler than holding the write lock across the open await.
        let path = self.archive_path(region);
        let reader = Arc::new(
            AsyncPmTilesReader::new_with_path(&path)
                .await
                .with_context(|| format!("Open PMTiles archive at {}", path.display()))?,
        );
        self.readers
            .write()
            .await
            .insert(region.id.clone(), Arc::clone(&reader));
        Ok(reader)
    }
}

#[cfg(test)]
mod tests {
    // The download/read paths require a live gateway and a real PMTiles archive,
    // which is integration-territory. Unit-level coverage of the repository CRUD
    // paths lives in `infrastructure::persistence::database::tests`.
}
