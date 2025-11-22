use anyhow::Result;
use serde_json::Value;

use crate::types::FrbRoute;

/// Fetch a route from the public OSRM demo server and convert it to
/// `FrbRoute`. Expects lat/lon inputs.
pub async fn fetch_osrm_route(
    start_lat: f64,
    start_lon: f64,
    end_lat: f64,
    end_lon: f64,
) -> Result<FrbRoute> {
    // OSRM expects lon,lat ordering in the path
    let start = format!("{},{}", start_lon, start_lat);
    let end = format!("{},{}", end_lon, end_lat);
    let url = format!(
        "https://router.project-osrm.org/route/v1/driving/{};{}?overview=full&geometries=geojson&steps=false&alternatives=false",
        start, end
    );

    let resp = reqwest::get(&url).await?;
    let json: Value = resp.json().await?;

    if json.get("code").and_then(|v| v.as_str()) != Some("Ok") {
        return Err(anyhow::anyhow!("OSRM returned error: {:?}", json));
    }

    let routes = json
        .get("routes")
        .and_then(|r| r.as_array())
        .cloned()
        .unwrap_or_default();
    if routes.is_empty() {
        return Err(anyhow::anyhow!("No routes from OSRM"));
    }

    let first = &routes[0];
    let distance = first.get("distance").and_then(|d| d.as_f64()).unwrap_or(0.0);
    let duration = first.get("duration").and_then(|d| d.as_f64()).unwrap_or(0.0);

    let mut waypoints: Vec<[f64; 2]> = Vec::new();
    if let Some(geometry) = first.get("geometry") {
        if let Some(coords) = geometry.get("coordinates").and_then(|c| c.as_array()) {
            for c in coords {
                if let Some(arr) = c.as_array() {
                    if arr.len() >= 2 {
                        if let (Some(lon), Some(lat)) = (arr[0].as_f64(), arr[1].as_f64()) {
                            waypoints.push([lat, lon]);
                        }
                    }
                }
            }
        }
    }

    let route = FrbRoute {
        id: format!("osrm-{}", chrono::Utc::now().timestamp_millis()),
        polyline: String::new(),
        distance_m: distance,
        duration_s: duration,
        name: "OSRM route".to_string(),
        waypoints,
    };

    Ok(route)
}
