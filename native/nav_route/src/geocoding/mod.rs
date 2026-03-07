// Nominatim Geocoding Adapter — implements nav_core's GeocodingService port.
use anyhow::{Context, Result};
use async_trait::async_trait;
use nav_core::{GeocodingSearchResult, Position};

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
        Self { base_url, client }
    }
}

// Keep old name as alias for backwards compatibility
pub type PhotonGeocodingService = NominatimGeocodingService;

#[async_trait]
impl nav_core::GeocodingService for NominatimGeocodingService {
    async fn geocode(
        &self,
        address: &str,
        limit: Option<u32>,
    ) -> Result<Vec<GeocodingSearchResult>> {
        let url = format!(
            "{}/search?q={}&format=json&limit={}&addressdetails=1",
            self.base_url,
            urlencoding::encode(address),
            limit.unwrap_or(10)
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

        let results = data
            .iter()
            .filter_map(|item| {
                let lat = item["lat"].as_str()?.parse::<f64>().ok()?;
                let lon = item["lon"].as_str()?.parse::<f64>().ok()?;
                let position = Position::new(lat, lon).ok()?;
                let display_name = item["display_name"].as_str()?.to_string();
                let osm_type = item["osm_type"].as_str().map(|s| s.to_string());
                let osm_id = item["osm_id"].as_i64();
                let addr = &item["address"];
                let name = item["name"].as_str().map(|s| s.to_string());
                let city = addr["city"]
                    .as_str()
                    .or(addr["town"].as_str())
                    .or(addr["village"].as_str())
                    .map(|s| s.to_string());
                let country = addr["country"].as_str().map(|s| s.to_string());
                Some(GeocodingSearchResult {
                    position,
                    display_name,
                    name,
                    city,
                    country,
                    osm_type,
                    osm_id,
                })
            })
            .collect();

        Ok(results)
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

        if let Some(display_name) = data["display_name"].as_str() {
            return Ok(display_name.to_string());
        }

        let address_obj = &data["address"];
        let mut parts = Vec::new();
        if let Some(road) = address_obj["road"].as_str() {
            parts.push(road.to_string());
        }
        if let Some(house_number) = address_obj["house_number"].as_str() {
            parts.insert(0, house_number.to_string());
        }
        if let Some(city) = address_obj["city"]
            .as_str()
            .or(address_obj["town"].as_str())
            .or(address_obj["village"].as_str())
        {
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
