// OSRM Adapter - Implementation of RouteService port. Returns Nav-IR Route.
use crate::domain::{ports::RouteService, value_objects::*};
use anyhow::{Context, Result};
use async_trait::async_trait;
use chrono::Utc;
use nav_ir::{
    BoundingBox, EncodedPolyline, GeometryConfidence, GeometrySource, Route as NavIrRoute,
    RouteGeometry, RouteMetadata, RoutePolicies, RouteSegment, SegmentConstraints, SegmentId,
    SegmentIntent, Waypoint as NavIrWaypoint, WaypointId, WaypointKind,
};

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
            "{}/route/v1/driving/{}?overview=full&geometries=polyline&steps=true",
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

        let osrm_response: serde_json::Value = response
            .json()
            .await
            .context("Failed to parse OSRM response")?;

        let routes = osrm_response["routes"]
            .as_array()
            .context("No routes in response")?;
        let route_data = routes.first().context("Empty routes array")?;

        let distance_meters = route_data["distance"].as_f64().unwrap_or(0.0);
        let duration_seconds = route_data["duration"].as_f64().unwrap_or(0.0) as u32;
        let geometry = route_data["geometry"]
            .as_str()
            .context("Missing geometry")?;

        let decoded =
            polyline::decode_polyline(geometry, 5).context("Failed to decode polyline")?;
        let (min_lat, max_lat, min_lon, max_lon) = decoded.coords().fold(
            (90.0_f64, -90.0_f64, 180.0_f64, -180.0_f64),
            |(min_lat, max_lat, min_lon, max_lon), c| {
                (
                    min_lat.min(c.y),
                    max_lat.max(c.y),
                    min_lon.min(c.x),
                    max_lon.max(c.x),
                )
            },
        );

        let nav_ir_waypoints: Vec<NavIrWaypoint> = waypoints
            .iter()
            .enumerate()
            .map(|(i, pos)| {
                let kind = if i == 0 {
                    WaypointKind::Start
                } else if i == waypoints.len() - 1 {
                    WaypointKind::Stop
                } else {
                    WaypointKind::Via
                };
                NavIrWaypoint {
                    id: WaypointId::new(),
                    coordinate: nav_ir::Coordinate::new(pos.latitude, pos.longitude),
                    kind,
                    radius_m: None,
                    name: None,
                    description: None,
                    role: None,
                    category: None,
                    geometry_ref: None,
                }
            })
            .collect();

        let now = Utc::now();
        let nav_ir_route = NavIrRoute {
            schema_version: NavIrRoute::CURRENT_SCHEMA_VERSION,
            id: nav_ir::RouteId::new(),
            metadata: RouteMetadata {
                name: String::new(),
                description: None,
                created_at: now,
                updated_at: now,
                total_distance_m: Some(distance_meters),
                estimated_duration_s: Some(duration_seconds as u64),
                tags: vec![],
                source: None,
            },
            segments: vec![RouteSegment {
                id: SegmentId::new(),
                intent: SegmentIntent::Recalculatable,
                geometry: RouteGeometry {
                    polyline: EncodedPolyline(geometry.to_string()),
                    source: GeometrySource::SnappedToGraph,
                    confidence: GeometryConfidence::High,
                    bounding_box: BoundingBox {
                        min_lat,
                        min_lon,
                        max_lat,
                        max_lon,
                    },
                },
                waypoints: nav_ir_waypoints,
                legs: vec![],
                instructions: vec![],
                constraints: SegmentConstraints::default(),
            }],
            policies: RoutePolicies::default(),
        };

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
