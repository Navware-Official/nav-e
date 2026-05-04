//! nav-dsp adapter for `nav_core::TileArchiveService`.
//!
//! Talks to the gateway at `{base_url}/v1/tiles/regions` and
//! `{base_url}/v1/tiles/download/{region_id}`. Auth is intentionally not
//! attached yet — gating these endpoints behind JWT is a follow-up.

use anyhow::{anyhow, Context, Result};
use async_trait::async_trait;
use futures_util::StreamExt;
use nav_core::{DownloadedRegion, RegionMetadata, TileArchiveService};
use std::path::Path;
use tokio::fs::File;
use tokio::io::AsyncWriteExt;

use super::config;

pub struct NavDspTileArchiveService {
    client: reqwest::Client,
}

impl NavDspTileArchiveService {
    pub fn new() -> Self {
        let client = reqwest::Client::builder()
            .user_agent("nav-e/1.0")
            .build()
            .expect("Failed to build HTTP client");
        Self { client }
    }

    fn base_url(&self) -> Result<String> {
        let base = config::get_config().base_url;
        if base.is_empty() {
            return Err(anyhow!(
                "nav-dsp base_url not configured (call set_navdsp_config first)"
            ));
        }
        Ok(base.trim_end_matches('/').to_string())
    }
}

impl Default for NavDspTileArchiveService {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl TileArchiveService for NavDspTileArchiveService {
    async fn list_regions(&self) -> Result<Vec<RegionMetadata>> {
        let url = format!("{}/v1/tiles/regions", self.base_url()?);
        let response = self
            .client
            .get(&url)
            .send()
            .await
            .with_context(|| format!("GET {} failed", url))?
            .error_for_status()
            .with_context(|| format!("GET {} returned an error status", url))?;
        response
            .json::<Vec<RegionMetadata>>()
            .await
            .with_context(|| format!("Decode response from {}", url))
    }

    async fn download_region(
        &self,
        region_id: &str,
        dest_path: &Path,
    ) -> Result<DownloadedRegion> {
        let base = self.base_url()?;

        // Resolve catalog metadata first — name + bounds for the DB row. Cheap,
        // and gives us a clear error if the region isn't advertised.
        let regions = self.list_regions().await?;
        let metadata = regions
            .into_iter()
            .find(|r| r.region_id == region_id)
            .with_context(|| {
                format!("Region '{}' not advertised by the gateway", region_id)
            })?;

        // Stream the archive directly from the gateway — single GET, no JSON
        // pointer hop. The gateway proxies the tiles service body back to us.
        let archive_url = format!("{}/v1/tiles/download/{}", base, region_id);
        let response = self
            .client
            .get(&archive_url)
            .send()
            .await
            .with_context(|| format!("GET {} failed", archive_url))?
            .error_for_status()
            .with_context(|| format!("GET {} returned an error status", archive_url))?;

        // Write to a `.partial` file, then atomically rename on success.
        let partial_path = dest_path.with_extension("partial");
        if let Some(parent) = dest_path.parent() {
            tokio::fs::create_dir_all(parent)
                .await
                .with_context(|| format!("Create parent dir for {}", dest_path.display()))?;
        }
        let mut file = File::create(&partial_path)
            .await
            .with_context(|| format!("Create {}", partial_path.display()))?;

        // Chunk-by-chunk so we don't load the whole archive into memory.
        let mut bytes_written: u64 = 0;
        let mut stream = response.bytes_stream();
        while let Some(chunk) = stream.next().await {
            let chunk = chunk.context("Read chunk from archive download")?;
            file.write_all(&chunk)
                .await
                .with_context(|| format!("Write to {}", partial_path.display()))?;
            bytes_written += chunk.len() as u64;
        }
        file.flush()
            .await
            .with_context(|| format!("Flush {}", partial_path.display()))?;
        drop(file);

        tokio::fs::rename(&partial_path, dest_path)
            .await
            .with_context(|| {
                format!(
                    "Rename {} -> {}",
                    partial_path.display(),
                    dest_path.display()
                )
            })?;

        Ok(DownloadedRegion {
            region_id: metadata.region_id,
            name: metadata.name,
            bounds: metadata.bounds,
            size_bytes: bytes_written,
        })
    }
}
