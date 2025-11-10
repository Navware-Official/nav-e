use anyhow::{anyhow, Result};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct FrbGeocodingResult {
    pub place_id: i64,
    pub licence: Option<String>,
    pub osm_type: Option<String>,
    pub osm_id: Option<i64>,
    pub lat: String,
    pub lon: String,
    pub display_name: Option<String>,
    #[serde(rename = "class")]
    pub class_field: Option<String>,
    #[serde(rename = "type")]
    pub type_field: Option<String>,
    pub importance: Option<f64>,
    pub boundingbox: Option<Vec<String>>,
    pub address: Option<HashMap<String, String>>,
}

pub async fn search_raw_json(query: &str, limit: Option<u32>) -> Result<String> {
    if query.trim().is_empty() {
        return Ok("[]".to_string());
    }

    let limit = limit.unwrap_or(10);
    let client = Client::builder()
        .user_agent("nav-e-app/1.0 (email@example.com)")
        .build()?;

    let url = format!(
        "https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&q={}&limit={}",
        urlencoding::encode(query),
        limit
    );

    let resp = client.get(&url).send().await.map_err(|e| anyhow!(e))?;

    if !resp.status().is_success() {
        return Err(anyhow!("Geocoding request failed: {}", resp.status()));
    }

    let text = resp.text().await.map_err(|e| anyhow!(e))?;
    Ok(text)
}

pub async fn search_typed(query: &str, limit: Option<u32>) -> Result<Vec<FrbGeocodingResult>> {
    if query.trim().is_empty() {
        return Ok(vec![]);
    }

    let json = search_raw_json(query, limit).await?;
    let parsed: Vec<FrbGeocodingResult> = serde_json::from_str(&json)
        .map_err(|e| anyhow!("Failed to parse geocoding response: {}", e))?;
    Ok(parsed)
}
