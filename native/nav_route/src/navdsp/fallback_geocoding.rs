use anyhow::Result;
use async_trait::async_trait;
use nav_core::{GeocodingSearchResult, Position};
use std::sync::Arc;

use super::config;
use super::geocoding::NavDspGeocodingService;
use crate::NominatimGeocodingService;

pub struct FallbackGeocodingService {
    navdsp: Arc<NavDspGeocodingService>,
    nominatim: Arc<NominatimGeocodingService>,
}

impl FallbackGeocodingService {
    pub fn new(
        navdsp: Arc<NavDspGeocodingService>,
        nominatim: Arc<NominatimGeocodingService>,
    ) -> Self {
        Self { navdsp, nominatim }
    }

    fn should_use_navdsp(&self) -> bool {
        let cfg = config::get_config();
        cfg.geocoding_enabled && !cfg.base_url.is_empty()
    }
}

#[async_trait]
impl nav_core::GeocodingService for FallbackGeocodingService {
    async fn geocode(
        &self,
        address: &str,
        limit: Option<u32>,
    ) -> Result<Vec<GeocodingSearchResult>> {
        if self.should_use_navdsp() {
            match self.navdsp.geocode(address, limit).await {
                Ok(results) => return Ok(results),
                Err(e) => {
                    tracing::warn!("nav-dsp geocoding failed, falling back to Nominatim: {}", e);
                }
            }
        }
        self.nominatim.geocode(address, limit).await
    }

    async fn reverse_geocode(&self, position: Position) -> Result<String> {
        if self.should_use_navdsp() {
            match self.navdsp.reverse_geocode(position).await {
                Ok(result) => return Ok(result),
                Err(e) => {
                    tracing::warn!(
                        "nav-dsp reverse geocoding failed, falling back to Nominatim: {}",
                        e
                    );
                }
            }
        }
        self.nominatim.reverse_geocode(position).await
    }
}
