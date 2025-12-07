// Geocoding Adapter - Implementation of GeocodingService port
use crate::domain::{ports::GeocodingService, value_objects::Position};
use anyhow::{Context, Result};
use async_trait::async_trait;
use flutter_rust_bridge::frb;

#[frb(ignore)]
pub struct PhotonGeocodingService {
    base_url: String,
    client: reqwest::Client,
}

impl PhotonGeocodingService {
    pub fn new(base_url: String) -> Self {
        Self {
            base_url,
            client: reqwest::Client::new(),
        }
    }
}

#[async_trait]
impl GeocodingService for PhotonGeocodingService {
    async fn geocode(&self, address: &str) -> Result<Vec<Position>> {
        let url = format!("{}/api?q={}", self.base_url, urlencoding::encode(address));

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .context("Failed to send geocoding request")?;

        let data: serde_json::Value = response
            .json()
            .await
            .context("Failed to parse geocoding response")?;

        let features = data["features"]
            .as_array()
            .context("No features in response")?;

        let positions: Vec<Position> = features
            .iter()
            .filter_map(|feature| {
                let coords = feature["geometry"]["coordinates"].as_array()?;
                let lon = coords.first()?.as_f64()?;
                let lat = coords.get(1)?.as_f64()?;
                Position::new(lat, lon).ok()
            })
            .collect();

        Ok(positions)
    }

    async fn reverse_geocode(&self, position: Position) -> Result<String> {
        let url = format!(
            "{}/reverse?lon={}&lat={}",
            self.base_url, position.longitude, position.latitude
        );

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .context("Failed to send reverse geocoding request")?;

        let data: serde_json::Value = response
            .json()
            .await
            .context("Failed to parse reverse geocoding response")?;

        let features = data["features"]
            .as_array()
            .context("No features in response")?;

        let first = features.first().context("No results found")?;
        let properties = &first["properties"];

        // Build address string from properties
        let mut parts = Vec::new();
        if let Some(name) = properties["name"].as_str() {
            parts.push(name.to_string());
        }
        if let Some(street) = properties["street"].as_str() {
            parts.push(street.to_string());
        }
        if let Some(city) = properties["city"].as_str() {
            parts.push(city.to_string());
        }
        if let Some(country) = properties["country"].as_str() {
            parts.push(country.to_string());
        }

        Ok(parts.join(", "))
    }
}
