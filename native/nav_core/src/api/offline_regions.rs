//! Offline map regions API: registry in Rust DB, tile download and file write in Rust.

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

/// Delete an offline region by id and remove its tile directory.
pub fn delete_offline_region(id: String) -> Result<()> {
    get_container()
        .offline
        .delete_offline_region(DeleteOfflineRegionCommand { id })
}

/// Get list of tiles for a region as JSON array of {z, x, y}.
pub fn get_offline_region_tile_list(region_id: String) -> Result<String> {
    query_json(|| {
        get_container()
            .offline
            .get_tile_list(GetOfflineRegionTileListQuery { region_id })
    })
}

/// Read one tile file for a region. Returns raw .pbf bytes.
pub fn get_offline_region_tile_bytes(region_id: String, z: i32, x: i32, y: i32) -> Result<Vec<u8>> {
    get_container()
        .offline
        .get_tile_bytes(GetOfflineRegionTileBytesQuery { region_id, z, x, y })
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

/// Download a region: fetch tiles, write to directory, insert into DB. Returns region JSON.
#[allow(clippy::too_many_arguments)]
pub fn download_offline_region(
    name: String,
    north: f64,
    south: f64,
    east: f64,
    west: f64,
    min_zoom: i32,
    max_zoom: i32,
    tile_url_template: Option<String>,
) -> Result<String> {
    get_container()
        .offline
        .download_offline_region(DownloadOfflineRegionCommand {
            name,
            north,
            south,
            east,
            west,
            min_zoom,
            max_zoom,
            tile_url_template,
        })
}
