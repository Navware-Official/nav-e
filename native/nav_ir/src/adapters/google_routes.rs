//! Google Routes API v2 response → Nav-IR Route.
//!
//! Normalizes the response from POST /directions/v2:computeRoutes into a Nav-IR Route.
//! Google encodes polylines at precision 5 (same as OSRM), so no re-encoding is needed.
//! Distance is already in meters. Duration is a string in "123s" format.

use crate::{
    BoundingBox, Coordinate, EncodedPolyline, GeometryConfidence, GeometrySource, Route,
    RouteGeometry, RouteMetadata, RoutePolicies, RouteSegment, SegmentConstraints, SegmentId,
    SegmentIntent, Waypoint, WaypointId, WaypointKind,
};
use chrono::Utc;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
struct GoogleRoutesResponse {
    #[serde(default)]
    routes: Vec<GoogleRoute>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct GoogleRoute {
    polyline: GooglePolyline,
    distance_meters: u64,
    /// Duration string in "123s" format.
    duration: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct GooglePolyline {
    encoded_polyline: String,
}

/// Normalize a Google Routes API v2 `/directions/v2:computeRoutes` JSON response into a Nav-IR Route.
///
/// `waypoints` provides the original (lat, lon) pairs so the route can have correct Start/Via/Stop
/// markers. If empty, the first and last polyline points are used instead.
pub fn normalize_google_routes(json: &str, waypoints: &[(f64, f64)]) -> Result<Route, String> {
    let response: GoogleRoutesResponse =
        serde_json::from_str(json).map_err(|e| format!("Invalid Google Routes JSON: {}", e))?;

    let route_data = response
        .routes
        .first()
        .ok_or_else(|| "Google Routes response has no routes".to_string())?;

    let geometry = &route_data.polyline.encoded_polyline;
    let decoded = polyline::decode_polyline(geometry, 5)
        .map_err(|e| format!("Failed to decode Google Routes polyline: {}", e))?;

    let coords: Vec<_> = decoded.0;
    if coords.len() < 2 {
        return Err("Google Routes geometry has fewer than 2 points".to_string());
    }

    let (min_lat, max_lat, min_lon, max_lon) = coords.iter().fold(
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

    // Duration: strip trailing "s", parse as u64 (e.g. "1234s" → 1234)
    let duration_str = route_data.duration.trim_end_matches('s');
    let duration_s: u64 = duration_str
        .parse()
        .map_err(|_| format!("Failed to parse duration '{}'", route_data.duration))?;

    let wps: Vec<Waypoint> = if waypoints.is_empty() {
        let first = &coords[0];
        let last = &coords[coords.len() - 1];
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
        let n = waypoints.len();
        waypoints
            .iter()
            .enumerate()
            .map(|(i, &(lat, lon))| {
                let kind = if i == 0 {
                    WaypointKind::Start
                } else if i == n - 1 {
                    WaypointKind::Stop
                } else {
                    WaypointKind::Via
                };
                Waypoint {
                    id: WaypointId::new(),
                    coordinate: Coordinate::new(lat, lon),
                    kind,
                    radius_m: None,
                    name: None,
                    description: None,
                    role: None,
                    category: None,
                    geometry_ref: None,
                }
            })
            .collect()
    };

    if wps.len() < 2 {
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
            total_distance_m: Some(route_data.distance_meters as f64),
            estimated_duration_s: Some(duration_s),
            tags: vec![],
            source: None,
        },
        segments: vec![RouteSegment {
            id: SegmentId::new(),
            intent: SegmentIntent::Recalculatable,
            geometry: RouteGeometry {
                polyline: EncodedPolyline(geometry.clone()),
                source: GeometrySource::SnappedToGraph,
                confidence: GeometryConfidence::High,
                bounding_box: BoundingBox {
                    min_lat,
                    min_lon,
                    max_lat,
                    max_lon,
                },
            },
            waypoints: wps,
            legs: vec![],
            instructions: vec![],
            constraints: SegmentConstraints::default(),
        }],
        policies: RoutePolicies::default(),
    };

    route.validate().map_err(|e| e.to_string())?;
    Ok(route)
}

#[cfg(test)]
mod tests {
    use super::*;
    use geo_types::Coord;

    fn make_polyline5(coords: &[(f64, f64)]) -> String {
        let geo_coords: Vec<Coord<f64>> = coords
            .iter()
            .map(|(lat, lon)| Coord { x: *lon, y: *lat })
            .collect();
        polyline::encode_coordinates(geo_coords, 5).unwrap()
    }

    #[test]
    fn normalize_google_routes_basic() {
        let polyline = make_polyline5(&[(40.7128, -74.0060), (40.7580, -73.9855)]);
        let json = format!(
            r#"{{
                "routes": [{{
                    "polyline": {{"encodedPolyline": "{polyline}"}},
                    "distanceMeters": 8500,
                    "duration": "1020s"
                }}]
            }}"#
        );

        let waypoints = [(40.7128, -74.0060), (40.7580, -73.9855)];
        let route = normalize_google_routes(&json, &waypoints).unwrap();
        assert_eq!(route.segments.len(), 1);
        let seg = &route.segments[0];
        assert_eq!(seg.waypoints.len(), 2);
        assert_eq!(seg.waypoints[0].kind, WaypointKind::Start);
        assert_eq!(seg.waypoints[1].kind, WaypointKind::Stop);
        assert!((route.metadata.total_distance_m.unwrap() - 8500.0).abs() < 1.0);
        assert_eq!(route.metadata.estimated_duration_s, Some(1020));
        assert_eq!(seg.intent, SegmentIntent::Recalculatable);
    }

    #[test]
    fn normalize_google_routes_via_waypoint() {
        let polyline = make_polyline5(&[
            (40.7128, -74.0060),
            (40.7350, -73.9950),
            (40.7580, -73.9855),
        ]);
        let json = format!(
            r#"{{
                "routes": [{{
                    "polyline": {{"encodedPolyline": "{polyline}"}},
                    "distanceMeters": 12000,
                    "duration": "1500s"
                }}]
            }}"#
        );

        let waypoints = [
            (40.7128, -74.0060),
            (40.7350, -73.9950),
            (40.7580, -73.9855),
        ];
        let route = normalize_google_routes(&json, &waypoints).unwrap();
        let seg = &route.segments[0];
        assert_eq!(seg.waypoints.len(), 3);
        assert_eq!(seg.waypoints[1].kind, WaypointKind::Via);
    }

    #[test]
    fn normalize_google_routes_fallback_to_geometry_endpoints() {
        let polyline = make_polyline5(&[(40.7128, -74.0060), (40.7580, -73.9855)]);
        let json = format!(
            r#"{{
                "routes": [{{
                    "polyline": {{"encodedPolyline": "{polyline}"}},
                    "distanceMeters": 5000,
                    "duration": "600s"
                }}]
            }}"#
        );

        let route = normalize_google_routes(&json, &[]).unwrap();
        let seg = &route.segments[0];
        assert_eq!(seg.waypoints.len(), 2);
        assert_eq!(seg.waypoints[0].kind, WaypointKind::Start);
        assert_eq!(seg.waypoints[1].kind, WaypointKind::Stop);
    }

    #[test]
    fn normalize_google_routes_rejects_empty_routes() {
        let json = r#"{"routes": []}"#;
        assert!(normalize_google_routes(json, &[]).is_err());
    }

    #[test]
    fn normalize_google_routes_parses_duration_without_s_suffix() {
        // Defensive: handle "1020" without the "s" suffix
        let polyline = make_polyline5(&[(40.7128, -74.0060), (40.7580, -73.9855)]);
        let json = format!(
            r#"{{
                "routes": [{{
                    "polyline": {{"encodedPolyline": "{polyline}"}},
                    "distanceMeters": 5000,
                    "duration": "1020"
                }}]
            }}"#
        );
        // "1020".trim_end_matches('s') == "1020", so still valid
        let route = normalize_google_routes(&json, &[]).unwrap();
        assert_eq!(route.metadata.estimated_duration_s, Some(1020));
    }
}
