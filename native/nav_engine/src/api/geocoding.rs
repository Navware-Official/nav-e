/// Geocoding APIs
use anyhow::{Context, Result};

use super::{dto::*, helpers::*};
use crate::application::{handlers::*, queries::*, traits::QueryHandler};
use crate::domain::value_objects::*;

/// Search for locations by address/name

pub fn geocode_search(query: String, limit: Option<u32>) -> Result<String> {
    eprintln!("[GEOCODING RUST] Function called with query: {}", query);

    let rt = match tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
    {
        Ok(rt) => {
            eprintln!("[GEOCODING RUST] Runtime created successfully");
            rt
        }
        Err(e) => {
            eprintln!("[GEOCODING RUST ERROR] Failed to build runtime: {}", e);
            return Err(anyhow::anyhow!("Failed to build tokio runtime: {}", e));
        }
    };

    let result = rt.block_on(async {
        eprintln!("[GEOCODING RUST] Inside async block");
        // Call Nominatim API for geocoding
        let url = format!(
            "https://nominatim.openstreetmap.org/search?q={}&format=json&limit={}&addressdetails=1",
            urlencoding::encode(&query),
            limit.unwrap_or(10)
        );

        eprintln!("[GEOCODING RUST] Query: {}", query);
        eprintln!("[GEOCODING RUST] URL: {}", url);

        let client = reqwest::Client::builder()
            .user_agent("NavE Navigation App/1.0")
            .build()
            .map_err(|e| {
                eprintln!("[GEOCODING RUST ERROR] Failed to build client: {}", e);
                e
            })?;

        eprintln!("[GEOCODING RUST] Sending request...");
        let response = client
            .get(&url)
            .send()
            .await
            .map_err(|e| {
                eprintln!("[GEOCODING RUST ERROR] Request failed: {}", e);
                e
            })
            .context("Failed to send geocoding request")?;

        eprintln!("[GEOCODING RUST] Response status: {}", response.status());

        let response_text = response.text().await.map_err(|e| {
            eprintln!("[GEOCODING RUST ERROR] Failed to read response text: {}", e);
            e
        })?;
        eprintln!(
            "[GEOCODING RUST] Response body length: {} bytes",
            response_text.len()
        );
        eprintln!("[GEOCODING RUST] Response body: {}", response_text);

        let data: Vec<serde_json::Value> = serde_json::from_str(&response_text)
            .map_err(|e| {
                eprintln!("[GEOCODING RUST ERROR] Failed to parse JSON: {}", e);
                e
            })
            .context("Failed to parse geocoding response")?;

        eprintln!("[GEOCODING RUST] Parsed {} results", data.len());

        let results: Vec<GeocodingResultDto> = data
            .iter()
            .filter_map(|item| {
                let lat = item["lat"].as_str()?.parse::<f64>().ok()?;
                let lon = item["lon"].as_str()?.parse::<f64>().ok()?;

                let display_name = item["display_name"].as_str()?.to_string();
                let osm_type = item["osm_type"].as_str().map(|s| s.to_string());
                let osm_id = item["osm_id"].as_i64();

                // Extract address details if available
                let address = &item["address"];
                let name = item["name"].as_str().map(|s| s.to_string());
                let city = address["city"]
                    .as_str()
                    .or(address["town"].as_str())
                    .or(address["village"].as_str())
                    .map(|s| s.to_string());
                let country = address["country"].as_str().map(|s| s.to_string());

                Some(GeocodingResultDto {
                    latitude: lat,
                    longitude: lon,
                    display_name,
                    name,
                    city,
                    country,
                    osm_type,
                    osm_id,
                })
            })
            .collect();

        eprintln!("[GEOCODING RUST] Returning {} results", results.len());
        let json_result = serde_json::to_string(&results).map_err(|e| {
            eprintln!("[GEOCODING RUST ERROR] Failed to serialize results: {}", e);
            e
        })?;
        eprintln!(
            "[GEOCODING RUST] JSON response length: {}",
            json_result.len()
        );

        Ok(json_result)
    });

    eprintln!("[GEOCODING RUST] Returning result from function");
    result
}

/// Reverse geocode coordinates to address

pub fn reverse_geocode(latitude: f64, longitude: f64) -> Result<String> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async {
        let ctx = super::get_context();
        let handler = ReverseGeocodeHandler::new(ctx.geocoding_service.clone());

        let position = Position::new(latitude, longitude).map_err(|e| anyhow::anyhow!(e))?;
        let query = ReverseGeocodeQuery { position };

        let address = handler.handle(query).await?;
        Ok(address)
    })
}
