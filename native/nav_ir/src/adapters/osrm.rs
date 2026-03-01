//! OSRM response → Nav-IR Route.
//!
//! Normalizes OSRM route/v1/driving JSON into a single Nav-IR Route (one segment, Recalculatable, SnappedToGraph).

use crate::{
    BoundingBox, EncodedPolyline, GeometryConfidence, GeometrySource, Coordinate, Route,
    RouteGeometry, RouteMetadata, RoutePolicies, RouteSegment, SegmentConstraints,
    SegmentId, SegmentIntent, Waypoint, WaypointId, WaypointKind,
};
use chrono::Utc;
use serde::Deserialize;

/// Minimal OSRM route/v1/driving response shape (waypoints + first route).
#[derive(Debug, Deserialize)]
pub struct OsrmResponse {
    #[serde(default)]
    pub waypoints: Vec<OsrmWaypoint>,
    pub routes: Vec<OsrmRoute>,
}

#[derive(Debug, Deserialize)]
pub struct OsrmWaypoint {
    #[serde(default)]
    pub name: Option<String>,
    /// [longitude, latitude]
    pub location: [f64; 2],
}

#[derive(Debug, Deserialize)]
pub struct OsrmRoute {
    pub distance: f64,
    pub duration: f64,
    pub geometry: String,
}

impl TryFrom<OsrmResponse> for Route {
    type Error = String;

    fn try_from(r: OsrmResponse) -> Result<Self, Self::Error> {
        let route_data = r
            .routes
            .first()
            .ok_or_else(|| "OSRM response has no routes".to_string())?;
        let geometry = route_data
            .geometry
            .as_str();
        let decoded = polyline::decode_polyline(geometry, 5)
            .map_err(|e| format!("Failed to decode OSRM polyline: {}", e))?;
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
        let waypoints: Vec<Waypoint> = if r.waypoints.is_empty() {
            let coords: Vec<_> = decoded.coords().collect();
            if coords.len() < 2 {
                return Err("OSRM geometry has fewer than 2 points".to_string());
            }
            let first = coords[0];
            let last = coords[coords.len() - 1];
            vec![
                Waypoint {
                    id: WaypointId::new(),
                    coordinate: Coordinate::new(first.y, first.x),
                    kind: WaypointKind::Start,
                    radius_m: None,
                    name: None,
                    description: None,
                    role: None,
                    category: None,
                    geometry_ref: None,
                },
                Waypoint {
                    id: WaypointId::new(),
                    coordinate: Coordinate::new(last.y, last.x),
                    kind: WaypointKind::Stop,
                    radius_m: None,
                    name: None,
                    description: None,
                    role: None,
                    category: None,
                    geometry_ref: None,
                },
            ]
        } else {
            r.waypoints
                .iter()
                .enumerate()
                .map(|(i, w)| {
                    let [lon, lat] = w.location;
                    let kind = if i == 0 {
                        WaypointKind::Start
                    } else if i == r.waypoints.len() - 1 {
                        WaypointKind::Stop
                    } else {
                        WaypointKind::Via
                    };
                    Waypoint {
                        id: WaypointId::new(),
                        coordinate: Coordinate::new(lat, lon),
                        kind,
                        radius_m: None,
                        name: w.name.clone(),
                        description: None,
                        role: None,
                        category: None,
                        geometry_ref: None,
                    }
                })
                .collect()
        };
        if waypoints.len() < 2 {
            return Err("Need at least two waypoints (Start and Stop)".to_string());
        }
        let now = Utc::now();
        let route = Route {
            schema_version: Route::CURRENT_SCHEMA_VERSION,
            id: crate::RouteId::new(),
            metadata: RouteMetadata {
                name: String::new(),
                description: None,
                created_at: now,
                updated_at: now,
                total_distance_m: Some(route_data.distance),
                estimated_duration_s: Some(route_data.duration as u64),
                tags: vec![],
                source: None,
            },
            segments: vec![RouteSegment {
                id: SegmentId::new(),
                intent: SegmentIntent::Recalculatable,
                geometry: RouteGeometry {
                    polyline: EncodedPolyline(route_data.geometry.clone()),
                    source: GeometrySource::SnappedToGraph,
                    confidence: GeometryConfidence::High,
                    bounding_box: BoundingBox {
                        min_lat,
                        min_lon,
                        max_lat,
                        max_lon,
                    },
                },
                waypoints,
                legs: vec![],
                instructions: vec![],
                constraints: SegmentConstraints::default(),
            }],
            policies: RoutePolicies::default(),
        };
        route.validate().map_err(|e| e.to_string())?;
        Ok(route)
    }
}

/// Normalize OSRM route JSON into a Nav-IR Route.
///
/// Expects the response from OSRM `route/v1/driving/{coords}?overview=full&geometries=polyline`.
/// Waypoints are taken from `response.waypoints` if present, otherwise from geometry endpoints.
pub fn normalize_osrm(json: &str) -> Result<Route, String> {
    let response: OsrmResponse =
        serde_json::from_str(json).map_err(|e| format!("Invalid OSRM JSON: {}", e))?;
    response.try_into()
}
