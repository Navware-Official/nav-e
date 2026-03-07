// OSRM Adapter - Implementation of RouteService port. Returns Nav-IR Route.
use crate::domain::{ports::RouteService, value_objects::*};
use anyhow::{Context, Result};
use async_trait::async_trait;
use nav_ir::{normalize_osrm, Route as NavIrRoute};

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
    async fn calculate_route(&self, waypoints: Vec<Position>) -> Result<NavIrRoute> {
        eprintln!("[RUST OSRM] Starting route calculation");
        let coords: Vec<String> = waypoints
            .iter()
            .map(|p| format!("{},{}", p.longitude, p.latitude))
            .collect();
        let coords_str = coords.join(";");

        let url = format!(
            "{}/route/v1/driving/{}?overview=full&geometries=polyline",
            self.base_url, coords_str
        );
        eprintln!("[RUST OSRM] Request URL: {}", url);

        let response = self
            .client
            .get(&url)
            .timeout(std::time::Duration::from_secs(10))
            .send()
            .await
            .context("Failed to send OSRM request")?;

        eprintln!(
            "[RUST OSRM] Received response with status: {}",
            response.status()
        );

        if !response.status().is_success() {
            let error_text = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());
            eprintln!("[RUST OSRM] Error response: {}", error_text);
            anyhow::bail!("OSRM returned error status: {}", error_text);
        }

        let response_text = response
            .text()
            .await
            .context("Failed to read OSRM response body")?;

        let nav_ir_route = normalize_osrm(&response_text)
            .map_err(|e| anyhow::anyhow!("OSRM normalization failed: {}", e))?;

        Ok(nav_ir_route)
    }

    async fn recalculate_from_position(
        &self,
        route: &NavIrRoute,
        current_position: Position,
    ) -> Result<NavIrRoute> {
        let waypoints: Vec<Position> = route
            .segments
            .iter()
            .flat_map(|s| s.waypoints.iter())
            .map(|w| Position::new(w.coordinate.latitude, w.coordinate.longitude).unwrap())
            .collect();
        if waypoints.is_empty() {
            return self.calculate_route(vec![current_position]).await;
        }
        let mut new_waypoints = vec![current_position];
        new_waypoints.extend(waypoints.into_iter().skip(1));
        self.calculate_route(new_waypoints).await
    }
}
