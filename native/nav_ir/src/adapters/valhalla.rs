//! Valhalla API response → Nav-IR Route.
//!
//! Normalizes the response from POST /route (Valhalla HTTP API) into a single Nav-IR Route.
//!
//! Critical precision note: Valhalla encodes `trip.legs[].shape` at **precision 6** (polyline6),
//! while Nav-IR uses precision 5 everywhere. This adapter decodes at 6 and re-encodes at 5.
//! Distance is in km in the summary — multiply by 1000 to get meters.

use crate::{
    BoundingBox, Coordinate, EncodedPolyline, GeometryConfidence, GeometrySource, Route,
    RouteGeometry, RouteMetadata, RoutePolicies, RouteSegment, SegmentConstraints, SegmentId,
    SegmentIntent, Waypoint, WaypointId, WaypointKind,
};
use chrono::Utc;
use geo_types::Coord;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
struct ValhallaResponse {
    trip: ValhallaTrip,
}

#[derive(Debug, Deserialize)]
struct ValhallaTrip {
    legs: Vec<ValhallaLeg>,
    summary: ValhallaSummary,
    #[serde(default)]
    locations: Vec<ValhallaLocation>,
}

#[derive(Debug, Deserialize)]
struct ValhallaLeg {
    shape: String,
}

#[derive(Debug, Deserialize)]
struct ValhallaSummary {
    /// Route length in **kilometers**.
    length: f64,
    /// Route duration in **seconds**.
    time: f64,
}

#[derive(Debug, Deserialize)]
struct ValhallaLocation {
    lat: f64,
    lon: f64,
}

/// Normalize a Valhalla POST `/route` JSON response into a Nav-IR Route.
///
/// Decodes `trip.legs[0].shape` at polyline precision 6, re-encodes at precision 5.
/// `trip.summary.length` (km) is converted to meters; `trip.summary.time` (seconds) used directly.
/// Waypoints are taken from `trip.locations` if present, otherwise from geometry endpoints.
pub fn normalize_valhalla(json: &str) -> Result<Route, String> {
    let response: ValhallaResponse =
        serde_json::from_str(json).map_err(|e| format!("Invalid Valhalla JSON: {}", e))?;
    let trip = &response.trip;

    let shape = trip
        .legs
        .first()
        .ok_or_else(|| "Valhalla response has no legs".to_string())?
        .shape
        .as_str();

    // Valhalla uses polyline6; Nav-IR uses precision 5.
    let decoded = polyline::decode_polyline(shape, 6)
        .map_err(|e| format!("Failed to decode Valhalla polyline6: {}", e))?;

    let coords: Vec<Coord<f64>> = decoded.0.clone();
    if coords.len() < 2 {
        return Err("Valhalla geometry has fewer than 2 points".to_string());
    }

    let re_encoded = polyline::encode_coordinates(coords.clone(), 5)
        .map_err(|e| format!("Failed to re-encode to polyline5: {}", e))?;

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

    let waypoints: Vec<Waypoint> = if trip.locations.is_empty() {
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
        let n = trip.locations.len();
        trip.locations
            .iter()
            .enumerate()
            .map(|(i, loc)| {
                let kind = if i == 0 {
                    WaypointKind::Start
                } else if i == n - 1 {
                    WaypointKind::Stop
                } else {
                    WaypointKind::Via
                };
                Waypoint {
                    id: WaypointId::new(),
                    coordinate: Coordinate::new(loc.lat, loc.lon),
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
            total_distance_m: Some(trip.summary.length * 1000.0),
            estimated_duration_s: Some(trip.summary.time as u64),
            tags: vec![],
            source: None,
        },
        segments: vec![RouteSegment {
            id: SegmentId::new(),
            intent: SegmentIntent::Recalculatable,
            geometry: RouteGeometry {
                polyline: EncodedPolyline(re_encoded),
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

#[cfg(test)]
mod tests {
    use super::*;

    fn make_polyline6(coords: &[(f64, f64)]) -> String {
        // coords are (lat, lon)
        let geo_coords: Vec<Coord<f64>> = coords
            .iter()
            .map(|(lat, lon)| Coord { x: *lon, y: *lat })
            .collect();
        polyline::encode_coordinates(geo_coords, 6).unwrap()
    }

    #[test]
    fn normalize_valhalla_two_locations() {
        let shape = make_polyline6(&[(40.7128, -74.0060), (40.7580, -73.9855)]);
        let json = format!(
            r#"{{
                "trip": {{
                    "legs": [{{"shape": "{shape}"}}],
                    "summary": {{"length": 5.0, "time": 600.0}},
                    "locations": [
                        {{"lat": 40.7128, "lon": -74.0060, "type": "break"}},
                        {{"lat": 40.7580, "lon": -73.9855, "type": "break"}}
                    ]
                }}
            }}"#
        );

        let route = normalize_valhalla(&json).unwrap();
        assert_eq!(route.segments.len(), 1);
        let seg = &route.segments[0];
        assert_eq!(seg.waypoints.len(), 2);
        assert_eq!(seg.waypoints[0].kind, WaypointKind::Start);
        assert_eq!(seg.waypoints[1].kind, WaypointKind::Stop);
        assert!((route.metadata.total_distance_m.unwrap() - 5000.0).abs() < 1.0);
        assert_eq!(route.metadata.estimated_duration_s, Some(600));
        assert_eq!(seg.intent, SegmentIntent::Recalculatable);
    }

    #[test]
    fn normalize_valhalla_via_waypoint() {
        let shape = make_polyline6(&[
            (40.7128, -74.0060),
            (40.7350, -73.9950),
            (40.7580, -73.9855),
        ]);
        let json = format!(
            r#"{{
                "trip": {{
                    "legs": [{{"shape": "{shape}"}}],
                    "summary": {{"length": 8.5, "time": 1020.0}},
                    "locations": [
                        {{"lat": 40.7128, "lon": -74.0060, "type": "break"}},
                        {{"lat": 40.7350, "lon": -73.9950, "type": "through"}},
                        {{"lat": 40.7580, "lon": -73.9855, "type": "break"}}
                    ]
                }}
            }}"#
        );

        let route = normalize_valhalla(&json).unwrap();
        let seg = &route.segments[0];
        assert_eq!(seg.waypoints.len(), 3);
        assert_eq!(seg.waypoints[0].kind, WaypointKind::Start);
        assert_eq!(seg.waypoints[1].kind, WaypointKind::Via);
        assert_eq!(seg.waypoints[2].kind, WaypointKind::Stop);
        assert!((route.metadata.total_distance_m.unwrap() - 8500.0).abs() < 1.0);
    }

    #[test]
    fn normalize_valhalla_fallback_to_geometry_endpoints() {
        // No locations — should use first/last polyline points
        let shape = make_polyline6(&[(40.7128, -74.0060), (40.7580, -73.9855)]);
        let json = format!(
            r#"{{
                "trip": {{
                    "legs": [{{"shape": "{shape}"}}],
                    "summary": {{"length": 5.0, "time": 600.0}},
                    "locations": []
                }}
            }}"#
        );

        let route = normalize_valhalla(&json).unwrap();
        let seg = &route.segments[0];
        assert_eq!(seg.waypoints.len(), 2);
        assert_eq!(seg.waypoints[0].kind, WaypointKind::Start);
        assert_eq!(seg.waypoints[1].kind, WaypointKind::Stop);
    }

    #[test]
    fn normalize_valhalla_rejects_missing_legs() {
        let json = r#"{
            "trip": {
                "legs": [],
                "summary": {"length": 5.0, "time": 600.0},
                "locations": []
            }
        }"#;
        assert!(normalize_valhalla(json).is_err());
    }
}
