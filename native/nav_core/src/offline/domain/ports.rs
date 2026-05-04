//! Ports — interfaces the offline bounded context expects from adapters.

use anyhow::Result;
use async_trait::async_trait;
use std::path::Path;

use super::value_objects::{DownloadedRegion, RegionMetadata};

/// Port for the nav-dsp tile catalog and PMTiles archive download.
///
/// Implemented by `nav_route::NavDspTileArchiveService`. Adapter is responsible
/// for resolving the gateway URL and any auth (currently none).
#[async_trait]
pub trait TileArchiveService: Send + Sync {
    /// List the regions advertised by the gateway.
    async fn list_regions(&self) -> Result<Vec<RegionMetadata>>;

    /// Download the PMTiles archive for `region_id` to `dest_path`.
    /// Returns the metadata + size of the file written.
    async fn download_region(
        &self,
        region_id: &str,
        dest_path: &Path,
    ) -> Result<DownloadedRegion>;
}
