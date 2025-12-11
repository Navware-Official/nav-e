// Geocoding Adapter - Implementation of GeocodingService port using Nominatim
use crate::domain::{ports::GeocodingService, value_objects::Position};
use anyhow::{Context, Result};
use async_trait::async_trait;


pub struct NominatimGeocodingService {
    base_url: String,
    client: reqwest::Client,
}

impl NominatimGeocodingService {
    pub fn new(base_url: String) -> Self {
        let client = reqwest::Client::builder()
            .user_agent("NavE Navigation App/1.0")
            .build()
            .expect("Failed to create HTTP client");
        
        Self {
            base_url,
            client,
        }
    }
}

// Keep old name as alias for backwards compatibility
pub type PhotonGeocodingService = NominatimGeocodingService;

#[async_trait]
impl GeocodingService for NominatimGeocodingService {
    async fn geocode(&self, address: &str) -> Result<Vec<Position>> {
        let url = format!(
            "{}/search?q={}&format=json&limit=10",
            self.base_url,
            urlencoding::encode(address)
        );

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .context("Failed to send geocoding request")?;

        let data: Vec<serde_json::Value> = response
            .json()
            .await
            .context("Failed to parse geocoding response")?;

        let positions: Vec<Position> = data
            .iter()
            .filter_map(|item| {
                let lat = item["lat"].as_str()?.parse::<f64>().ok()?;
                let lon = item["lon"].as_str()?.parse::<f64>().ok()?;
                Position::new(lat, lon).ok()
            })
            .collect();

        Ok(positions)
    }

    async fn reverse_geocode(&self, position: Position) -> Result<String> {
        let url = format!(
            "{}/reverse?lat={}&lon={}&format=json",
            self.base_url, position.latitude, position.longitude
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

        // Nominatim reverse returns a single object, not an array
        if let Some(display_name) = data["display_name"].as_str() {
            return Ok(display_name.to_string());
        }

        // Fallback: build address from parts
        let address_obj = &data["address"];
        let mut parts = Vec::new();
        
        if let Some(road) = address_obj["road"].as_str() {
            parts.push(road.to_string());
        }
        if let Some(house_number) = address_obj["house_number"].as_str() {
            parts.insert(0, house_number.to_string());
        }
        if let Some(city) = address_obj["city"].as_str()
            .or(address_obj["town"].as_str())
            .or(address_obj["village"].as_str()) {
            parts.push(city.to_string());
        }
        if let Some(country) = address_obj["country"].as_str() {
            parts.push(country.to_string());
        }

        if parts.is_empty() {
            Ok(format!("{:.6}, {:.6}", position.latitude, position.longitude))
        } else {
            Ok(parts.join(", "))
        }
    }
}
