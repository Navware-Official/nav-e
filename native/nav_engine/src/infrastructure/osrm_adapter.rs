// OSRM Adapter - Implementation of RouteService port
use crate::domain::{entities::Route, ports::RouteService, value_objects::*};
use anyhow::{Context, Result};
use async_trait::async_trait;


pub struct OsrmRouteService {
    base_url: String,
    client: reqwest::Client,
}

impl OsrmRouteService {
    pub fn new(base_url: String) -> Self {
        Self {
            base_url,
            client: reqwest::Client::new(),
        }
    }
}

#[async_trait]
impl RouteService for OsrmRouteService {
    async fn calculate_route(&self, waypoints: Vec<Position>) -> Result<Route> {
        eprintln!("[RUST OSRM] Starting route calculation");
        // Build OSRM request URL
        let coords: Vec<String> = waypoints
            .iter()
            .map(|p| format!("{},{}", p.longitude, p.latitude))
            .collect();
        let coords_str = coords.join(";");

        let url = format!(
            "{}/route/v1/driving/{}?overview=full&geometries=polyline&steps=true",
            self.base_url, coords_str
        );
        eprintln!("[RUST OSRM] Request URL: {}", url);

        // Make request
        eprintln!("[RUST OSRM] Sending HTTP request");
        let response = self
            .client
            .get(&url)
            .timeout(std::time::Duration::from_secs(10))
            .send()
            .await
            .context("Failed to send OSRM request")?;
        
        eprintln!("[RUST OSRM] Received response with status: {}", response.status());
        
        if !response.status().is_success() {
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            eprintln!("[RUST OSRM] Error response: {}", error_text);
            anyhow::bail!("OSRM returned error status: {}", error_text);
        }

        let osrm_response: serde_json::Value = response
            .json()
            .await
            .context("Failed to parse OSRM response")?;
        
        eprintln!("[RUST OSRM] Parsed response successfully");

        // Parse response
        let routes = osrm_response["routes"]
            .as_array()
            .context("No routes in response")?;
        let route_data = routes.first().context("Empty routes array")?;

        let distance_meters = route_data["distance"].as_f64().unwrap_or(0.0);
        let duration_seconds = route_data["duration"].as_f64().unwrap_or(0.0) as u32;

        // Decode polyline
        let geometry = route_data["geometry"]
            .as_str()
            .context("Missing geometry")?;
        let decoded = polyline::decode_polyline(geometry, 5)
            .context("Failed to decode polyline")?;
        let polyline: Vec<Position> = decoded.into_iter()
            .map(|coord| Position::new(coord.y, coord.x).unwrap())
            .collect();

        // Create waypoints
        let waypoint_objects: Vec<Waypoint> = waypoints
            .into_iter()
            .map(|pos| Waypoint::new(pos, None))
            .collect();

        Ok(Route::new(
            waypoint_objects,
            polyline,
            distance_meters,
            duration_seconds,
        ))
    }

    async fn recalculate_from_position(&self, route: &Route, current_position: Position) -> Result<Route> {
        // Find nearest point on route and recalculate from there
        // Simplified: just recalculate entire route with current position as start
        let mut waypoints = vec![current_position];
        waypoints.extend(route.waypoints.iter().map(|w| w.position));
        self.calculate_route(waypoints).await
    }
}
