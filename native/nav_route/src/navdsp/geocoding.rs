use anyhow::{Context, Result};
use async_trait::async_trait;
use nav_core::{GeocodingSearchResult, Position};

use super::config;

pub struct NavDspGeocodingService {
    client: reqwest::Client,
}

impl NavDspGeocodingService {
    pub fn new() -> Self {
        let client = reqwest::Client::builder()
            .user_agent("NavE Navigation App/1.0")
            .build()
            .expect("Failed to create HTTP client");
        Self { client }
    }
}

#[async_trait]
impl nav_core::GeocodingService for NavDspGeocodingService {
    async fn geocode(
        &self,
        address: &str,
        limit: Option<u32>,
    ) -> Result<Vec<GeocodingSearchResult>> {
        let cfg = config::get_config();
        let url = format!(
            "{}/v1/geocoding/search?q={}&limit={}",
            cfg.base_url,
            urlencoding::encode(address),
            limit.unwrap_or(10),
        );

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .context("Failed to send nav-dsp geocoding request")?;

        let data: Vec<serde_json::Value> = response
            .json()
            .await
            .context("Failed to parse nav-dsp geocoding response")?;

        let results = data
            .iter()
            .filter_map(|item| {
                let lat = item["lat"].as_f64()?;
                let lon = item["lon"].as_f64()?;
                let position = Position::new(lat, lon).ok()?;
                let name = item["name"].as_str()?.to_string();
                let display_name = name.clone();
                let city = item["city"].as_str().map(|s| s.to_string());
                let country = item["country"].as_str().map(|s| s.to_string());
                Some(GeocodingSearchResult {
                    position,
                    display_name,
                    name: Some(name),
                    city,
                    country,
                    osm_type: None,
                    osm_id: None,
                })
            })
            .collect();

        Ok(results)
    }

    async fn reverse_geocode(&self, position: Position) -> Result<String> {
        let cfg = config::get_config();
        let url = format!(
            "{}/v1/geocoding/reverse?lat={}&lon={}",
            cfg.base_url, position.latitude, position.longitude,
        );

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .context("Failed to send nav-dsp reverse geocoding request")?;

        let data: serde_json::Value = response
            .json()
            .await
            .context("Failed to parse nav-dsp reverse geocoding response")?;

        Ok(data["name"]
            .as_str()
            .unwrap_or(&format!("{:.6}, {:.6}", position.latitude, position.longitude))
            .to_string())
    }
}
