// Google Routes API v2 Adapter — implements nav_core's RouteService port.
//
// POST https://routes.googleapis.com/directions/v2:computeRoutes
// Headers: X-Goog-Api-Key, X-Goog-FieldMask
//
// API key is NOT hardcoded here. Pass it via `--dart-define=GOOGLE_ROUTES_KEY=...` at build
// time and hand it to `initialize_database(google_routes_api_key: Some(key))` in FFI.
use anyhow::{Context, Result};
use async_trait::async_trait;
use nav_ir::{normalize_google_routes, Route as NavIrRoute};
use serde_json::json;

const GOOGLE_ROUTES_URL: &str =
    "https://routes.googleapis.com/directions/v2:computeRoutes";

pub struct GoogleRoutesService {
    api_key: String,
    client: reqwest::Client,
}

impl GoogleRoutesService {
    pub fn new(api_key: String) -> Self {
        Self {
            api_key,
            client: reqwest::Client::new(),
        }
    }
}

#[async_trait]
impl nav_core::RouteService for GoogleRoutesService {
    async fn calculate_route(&self, waypoints: Vec<nav_core::Position>) -> Result<NavIrRoute> {
        if waypoints.len() < 2 {
            anyhow::bail!("Google Routes requires at least two waypoints");
        }

        let origin = &waypoints[0];
        let destination = &waypoints[waypoints.len() - 1];

        let mut body = json!({
            "origin": {
                "location": {
                    "latLng": {
                        "latitude": origin.latitude,
                        "longitude": origin.longitude
                    }
                }
            },
            "destination": {
                "location": {
                    "latLng": {
                        "latitude": destination.latitude,
                        "longitude": destination.longitude
                    }
                }
            },
            "travelMode": "DRIVE"
        });

        if waypoints.len() > 2 {
            let intermediates: Vec<serde_json::Value> = waypoints[1..waypoints.len() - 1]
                .iter()
                .map(|p| {
                    json!({
                        "location": {
                            "latLng": {
                                "latitude": p.latitude,
                                "longitude": p.longitude
                            }
                        }
                    })
                })
                .collect();
            body["intermediates"] = json!(intermediates);
        }

        let raw_waypoints: Vec<(f64, f64)> = waypoints
            .iter()
            .map(|p| (p.latitude, p.longitude))
            .collect();

        let response = self
            .client
            .post(GOOGLE_ROUTES_URL)
            .header("X-Goog-Api-Key", &self.api_key)
            .header(
                "X-Goog-FieldMask",
                "routes.polyline,routes.distanceMeters,routes.duration",
            )
            .json(&body)
            .timeout(std::time::Duration::from_secs(15))
            .send()
            .await
            .context("Failed to send Google Routes request")?;

        if !response.status().is_success() {
            let error_text = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());
            anyhow::bail!("Google Routes returned error status: {}", error_text);
        }

        let response_text = response
            .text()
            .await
            .context("Failed to read Google Routes response body")?;

        normalize_google_routes(&response_text, &raw_waypoints)
            .map_err(|e| anyhow::anyhow!("Google Routes normalization failed: {}", e))
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
