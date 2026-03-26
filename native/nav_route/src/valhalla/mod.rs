// Valhalla HTTP Adapter — implements nav_core's RouteService port.
//
// Supports both self-hosted Valhalla (e.g. valhalla1.openstreetmap.de) and
// Stadia Maps (pass api_key for the "api-key" header). Costing defaults to "auto".
use anyhow::{Context, Result};
use async_trait::async_trait;
use nav_ir::{normalize_valhalla, Route as NavIrRoute};
use serde_json::json;

pub struct ValhallaRouteService {
    base_url: String,
    /// Optional API key sent as the `api-key` header (required for Stadia Maps).
    api_key: Option<String>,
    /// Valhalla costing model: "auto" | "bicycle" | "pedestrian" | …
    costing: String,
    client: reqwest::Client,
}

impl ValhallaRouteService {
    pub fn new(base_url: String, api_key: Option<String>) -> Self {
        Self {
            base_url,
            api_key,
            costing: "auto".to_string(),
            client: reqwest::Client::new(),
        }
    }
}

#[async_trait]
impl nav_core::RouteService for ValhallaRouteService {
    async fn calculate_route(&self, waypoints: Vec<nav_core::Position>) -> Result<NavIrRoute> {
        let locations: Vec<serde_json::Value> = waypoints
            .iter()
            .map(|p| {
                json!({
                    "lon": p.longitude,
                    "lat": p.latitude,
                    "type": "break"
                })
            })
            .collect();

        let body = json!({
            "locations": locations,
            "costing": self.costing
        });

        let url = format!("{}/route", self.base_url);
        let mut request = self
            .client
            .post(&url)
            .json(&body)
            .timeout(std::time::Duration::from_secs(15));

        if let Some(key) = &self.api_key {
            request = request.header("api-key", key);
        }

        let response = request
            .send()
            .await
            .context("Failed to send Valhalla request")?;

        if !response.status().is_success() {
            let error_text = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());
            anyhow::bail!("Valhalla returned error status: {}", error_text);
        }

        let response_text = response
            .text()
            .await
            .context("Failed to read Valhalla response body")?;

        normalize_valhalla(&response_text)
            .map_err(|e| anyhow::anyhow!("Valhalla normalization failed: {}", e))
    }

    async fn recalculate_from_position(
        &self,
        route: &NavIrRoute,
        current_position: nav_core::Position,
    ) -> Result<NavIrRoute> {
        let waypoints: Vec<nav_core::Position> = route
            .segments
            .iter()
            .flat_map(|s| s.waypoints.iter())
            .map(|w| {
                nav_core::Position::new(w.coordinate.latitude, w.coordinate.longitude).unwrap()
            })
            .collect();
        if waypoints.is_empty() {
            return self.calculate_route(vec![current_position]).await;
        }
        let mut new_waypoints = vec![current_position];
        new_waypoints.extend(waypoints.into_iter().skip(1));
        self.calculate_route(new_waypoints).await
    }
}
