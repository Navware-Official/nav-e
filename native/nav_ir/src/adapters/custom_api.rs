//! Custom API / minimal input → Nav-IR Route.
//!
//! Build a Nav-IR Route from waypoints (lat, lon), encoded polyline, and optional distance/duration.
//! Use for custom routing engines or precomputed routes.

use crate::{
    BoundingBox, Coordinate, EncodedPolyline, GeometryConfidence, GeometrySource, Route,
    RouteGeometry, RouteMetadata, RoutePolicies, RouteSegment, SegmentConstraints, SegmentId,
    SegmentIntent, Waypoint, WaypointId, WaypointKind,
};
use chrono::Utc;

/// Normalize minimal custom input into a Nav-IR Route.
///
/// Builds a single segment with Recalculatable intent and SnappedToGraph geometry.
/// Waypoints are (latitude, longitude); first → Start, last → Stop, rest → Via.
/// Polyline must be a Google-style encoded polyline string.
pub fn normalize_custom(
    waypoints: &[(f64, f64)],
    polyline_encoded: &str,
    total_distance_m: Option<f64>,
    estimated_duration_s: Option<u64>,
) -> Result<Route, String> {
    if waypoints.len() < 2 {
        return Err("Need at least two waypoints (Start and Stop)".to_string());
    }
    let decoded = polyline::decode_polyline(polyline_encoded, 5)
        .map_err(|e| format!("Polyline decode: {}", e))?;
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
    let nav_waypoints: Vec<Waypoint> = waypoints
        .iter()
        .enumerate()
        .map(|(i, (lat, lon))| {
            let kind = if i == 0 {
                WaypointKind::Start
            } else if i == waypoints.len() - 1 {
                WaypointKind::Stop
            } else {
                WaypointKind::Via
            };
            Waypoint {
                id: WaypointId::new(),
                coordinate: Coordinate::new(*lat, *lon),
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
    let route = Route {
        schema_version: Route::CURRENT_SCHEMA_VERSION,
        id: crate::RouteId::new(),
        metadata: RouteMetadata {
            name: String::new(),
            description: None,
            created_at: now,
            updated_at: now,
            total_distance_m,
            estimated_duration_s,
            tags: vec![],
            source: None,
        },
        segments: vec![RouteSegment {
            id: SegmentId::new(),
            intent: SegmentIntent::Recalculatable,
            geometry: RouteGeometry {
                polyline: EncodedPolyline(polyline_encoded.to_string()),
                source: GeometrySource::SnappedToGraph,
                confidence: GeometryConfidence::High,
                bounding_box: BoundingBox {
                    min_lat,
                    min_lon,
                    max_lat,
                    max_lon,
                },
            },
            waypoints: nav_waypoints,
            legs: vec![],
            instructions: vec![],
            constraints: SegmentConstraints::default(),
        }],
        policies: RoutePolicies::default(),
    };
    route.validate().map_err(|e| e.to_string())?;
    Ok(route)
}
