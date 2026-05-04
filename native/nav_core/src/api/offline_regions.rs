//! Offline map regions API: registry in Rust DB, archive downloaded as PMTiles.

use anyhow::Result;

use crate::api::helpers::*;
use crate::app::container::get_container;
use crate::offline::commands::*;
use crate::offline::queries::*;

/// Get all offline regions as JSON array.
pub fn get_all_offline_regions() -> Result<String> {
    query_json(|| {
        get_container()
            .offline
            .get_all_offline_regions(GetAllOfflineRegionsQuery)
    })
}

/// Get one offline region by id as JSON object.
pub fn get_offline_region_by_id(id: String) -> Result<String> {
    query_json(|| {
        get_container()
            .offline
            .get_offline_region_by_id(GetOfflineRegionByIdQuery { id })
    })
}

/// Delete an offline region by id and remove its PMTiles archive.
pub fn delete_offline_region(id: String) -> Result<()> {
    command_async(|| async {
        get_container()
            .offline
            .delete_offline_region(DeleteOfflineRegionCommand { id })
            .await
    })
}

/// Get the bounds and zoom range stored in a region's PMTiles archive.
pub fn get_offline_region_tile_list(region_id: String) -> Result<String> {
    query_json_async(|| async {
        get_container()
            .offline
            .get_tile_list(GetOfflineRegionTileListQuery { region_id })
            .await
    })
}

/// Read one tile from a region's PMTiles archive. Returns raw vector-tile bytes.
pub fn get_offline_region_tile_bytes(region_id: String, z: i32, x: i32, y: i32) -> Result<Vec<u8>> {
    query_async(|| async {
        get_container()
            .offline
            .get_tile_bytes(GetOfflineRegionTileBytesQuery { region_id, z, x, y })
            .await
    })
}

/// Get region for viewport bbox as JSON object (or null).
pub fn get_offline_region_for_viewport(
    north: f64,
    south: f64,
    east: f64,
    west: f64,
) -> Result<String> {
    query_json(|| {
        get_container()
            .offline
            .get_offline_region_for_viewport(GetOfflineRegionForViewportQuery {
                north,
                south,
                east,
                west,
            })
    })
}

/// Get storage root path for offline regions.
pub fn get_offline_regions_storage_path() -> Result<String> {
    get_container()
        .offline
        .get_storage_path(GetStoragePathQuery)
}

/// List the regions advertised by the nav-dsp gateway as JSON array.
pub fn list_available_regions() -> Result<String> {
    query_json_async(|| async {
        get_container()
            .offline
            .list_available_regions(ListAvailableRegionsQuery)
            .await
    })
}

/// Download a region's PMTiles archive and register it in the DB. Returns region JSON.
pub fn download_offline_region(region_id: String) -> Result<String> {
    query_json_async(|| async {
        get_container()
            .offline
            .download_offline_region(DownloadOfflineRegionCommand { region_id })
            .await
    })
}
