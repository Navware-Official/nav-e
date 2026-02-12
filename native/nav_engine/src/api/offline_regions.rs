//! Offline map regions API: registry in Rust DB, tile download and file write in Rust.

use anyhow::{Context, Result};
use std::path::Path;

use super::helpers::*;
use crate::infrastructure::database::OfflineRegionEntity;

const DEFAULT_TILE_URL: &str = "https://demotiles.maplibre.org/tiles/{z}/{x}/{y}.pbf";

/// Tile XYZ from lat/lon (Web Mercator).
fn tile_xy(lat: f64, lon: f64, z: i32) -> (i32, i32) {
    let lat_rad = lat.to_radians();
    let n = 2f64.powi(z);
    let x = ((lon + 180.0) / 360.0 * n).floor() as i32;
    let y = ((1.0 - (lat_rad.tan() + (1.0 / lat_rad.cos())).ln() / std::f64::consts::PI) / 2.0 * n)
        .floor() as i32;
    (x, y)
}

/// Get all offline regions as JSON array.
pub fn get_all_offline_regions() -> Result<String> {
    query_json(|| super::get_context().offline_regions_repo.get_all())
}

/// Get one offline region by id as JSON object.
pub fn get_offline_region_by_id(id: String) -> Result<String> {
    let opt = super::get_context().offline_regions_repo.get_by_id(&id)?;
    serde_json::to_string(&opt).map_err(Into::into)
}

/// Delete an offline region by id and remove its tile directory.
pub fn delete_offline_region(id: String) -> Result<()> {
    let ctx = super::get_context();
    let region = ctx.offline_regions_repo.get_by_id(&id)?;
    ctx.offline_regions_repo.delete(&id)?;
    if let Some(r) = region {
        let storage = ctx.offline_regions_repo.get_storage_path()?;
        let dir = Path::new(&storage).join(&r.relative_path);
        let _ = std::fs::remove_dir_all(&dir);
    }
    Ok(())
}

/// Get region for viewport bbox as JSON object (or null).
pub fn get_offline_region_for_viewport(
    north: f64,
    south: f64,
    east: f64,
    west: f64,
) -> Result<String> {
    let opt = super::get_context()
        .offline_regions_repo
        .get_region_for_viewport(north, south, east, west)?;
    serde_json::to_string(&opt).map_err(Into::into)
}

/// Get storage root path for offline regions (e.g. app documents + "offline_regions").
pub fn get_offline_regions_storage_path() -> Result<String> {
    super::get_context()
        .offline_regions_repo
        .get_storage_path()
        .map_err(Into::into)
}

/// Download a region: fetch tiles, write to directory, insert into DB. Returns region JSON.
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
    let template = tile_url_template.unwrap_or_else(|| DEFAULT_TILE_URL.to_string());
    let ctx = super::get_context();
    let storage_path = ctx.offline_regions_repo.get_storage_path()?;
    let id = uuid::Uuid::new_v4().to_string();
    let relative_path = format!("region_{}", id);
    let region_dir = Path::new(&storage_path).join(&relative_path);
    std::fs::create_dir_all(&region_dir).context("Create offline region directory")?;

    let client = reqwest::blocking::Client::builder()
        .user_agent("nav-e/1.0 (offline maps)")
        .build()
        .context("Build HTTP client")?;

    let mut size_bytes: i64 = 0;
    for z in min_zoom..=max_zoom {
        let (tl_x, tl_y) = tile_xy(north, west, z);
        let (br_x, br_y) = tile_xy(south, east, z);
        let min_x = tl_x.min(br_x);
        let max_x = tl_x.max(br_x);
        let min_y = tl_y.min(br_y);
        let max_y = tl_y.max(br_y);

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
                                    let _ = std::fs::create_dir_all(parent);
                                }
                                if std::fs::write(&tile_path, &*bytes).is_ok() {
                                    size_bytes += bytes.len() as i64;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    let created_at = chrono::Utc::now().timestamp_millis();
    let entity = OfflineRegionEntity {
        id: id.clone(),
        name: name.clone(),
        north,
        south,
        east,
        west,
        min_zoom,
        max_zoom,
        relative_path: relative_path.clone(),
        size_bytes,
        created_at,
    };
    ctx.offline_regions_repo.insert(&entity)?;
    serde_json::to_string(&entity).map_err(Into::into)
}
