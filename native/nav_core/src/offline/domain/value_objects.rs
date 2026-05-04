//! Value types shared between the offline bounded context and adapters that
//! talk to the nav-dsp tile catalog.

use serde::{Deserialize, Serialize};

/// Bounding box for a region. Field names match the gateway JSON wire format.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RegionBounds {
    pub north: f64,
    pub south: f64,
    pub east: f64,
    pub west: f64,
}

/// One entry from `GET /v1/tiles/regions`.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RegionMetadata {
    #[serde(rename = "region_id")]
    pub region_id: String,
    pub name: String,
    #[serde(rename = "size_mb")]
    pub size_mb: u64,
    pub bounds: RegionBounds,
}

/// Result of a successful region archive download.
#[derive(Debug, Clone)]
pub struct DownloadedRegion {
    pub region_id: String,
    pub name: String,
    pub bounds: RegionBounds,
    pub size_bytes: u64,
}
