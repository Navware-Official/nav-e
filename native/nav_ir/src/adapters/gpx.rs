//! GPX bytes → Nav-IR Route.
//!
//! Normalizes GPX track/route into a single Nav-IR Route (one segment, FixedGeometry, ImportedExact).
//! Computes total distance from track/route points; optionally estimates duration from distance.

use crate::{
    BoundingBox, Coordinate, EncodedPolyline, GeometryConfidence, GeometrySource, ImportSource,
    Route, RouteGeometry, RouteMetadata, RoutePolicies, RouteSegment, SegmentConstraints,
    SegmentId, SegmentIntent, Waypoint, WaypointId, WaypointKind,
};
use chrono::Utc;
use geo_types::Coord;
use std::io::BufReader;

/// Approximate haversine distance in meters between (lat1, lon1) and (lat2, lon2).
fn haversine_m(lat1: f64, lon1: f64, lat2: f64, lon2: f64) -> f64 {
    const R: f64 = 6_371_000.0; // Earth radius in meters
    let lat1 = lat1.to_radians();
    let lat2 = lat2.to_radians();
    let dlat = lat2 - lat1;
    let dlon = (lon2 - lon1).to_radians();
    let a = (dlat / 2.0).sin().mul_add(
        (dlat / 2.0).sin(),
        lat1.cos() * lat2.cos() * (dlon / 2.0).sin() * (dlon / 2.0).sin(),
    );
    let c = 2.0 * a.sqrt().atan2((1.0 - a).sqrt());
    R * c
}

/// Total distance in meters along the sequence of points.
fn total_distance_m(points: &[(f64, f64)]) -> f64 {
    if points.len() < 2 {
        return 0.0;
    }
    points
        .windows(2)
        .map(|w| haversine_m(w[0].0, w[0].1, w[1].0, w[1].1))
        .sum()
}

/// Normalize GPX bytes (track or route) into a Nav-IR Route.
///
/// Uses the first track; all segments are flattened into one polyline. First point → Start waypoint,
/// last point → Stop waypoint. Intent is FixedGeometry, source ImportedExact.
pub fn normalize_gpx(bytes: &[u8]) -> Result<Route, String> {
    let reader = BufReader::new(bytes);
    let gpx = gpx::read(reader).map_err(|e| format!("GPX parse error: {}", e))?;

    let points: Vec<(f64, f64)> = if !gpx.tracks.is_empty() {
        gpx.tracks[0]
            .segments
            .iter()
            .flat_map(|seg| seg.points.iter())
            .map(|pt| {
                let c = pt.point();
                (c.y(), c.x())
            })
            .collect()
    } else if !gpx.routes.is_empty() {
        gpx.routes[0]
            .points
            .iter()
            .map(|wpt| {
                let c = wpt.point();
                (c.y(), c.x())
            })
            .collect()
    } else {
        return Err("GPX has no tracks or routes".to_string());
    };

    if points.len() < 2 {
        return Err("GPX track/route has fewer than 2 points".to_string());
    }

    let total_distance_m = total_distance_m(&points);
    // Estimate duration when not in GPX: assume ~15 km/h (e.g. cycling) -> 240 s per km
    let estimated_duration_s = if total_distance_m > 0.0 {
        Some((total_distance_m / 1000.0 * 240.0).round() as u64)
    } else {
        None
    };

    let coords: Vec<Coord<f64>> = points
        .iter()
        .map(|(lat, lon)| Coord { x: *lon, y: *lat })
        .collect();
    let polyline_str = polyline::encode_coordinates(coords.clone(), 5)
        .map_err(|e| format!("Polyline encode: {}", e))?;

    let (min_lat, max_lat, min_lon, max_lon) = points.iter().fold(
        (90.0_f64, -90.0_f64, 180.0_f64, -180.0_f64),
        |(min_lat, max_lat, min_lon, max_lon), (lat, lon)| {
            (
                min_lat.min(*lat),
                max_lat.max(*lat),
                min_lon.min(*lon),
                max_lon.max(*lon),
            )
        },
    );

    let name = gpx
        .tracks
        .first()
        .and_then(|t| t.name.as_deref())
        .or_else(|| gpx.routes.first().and_then(|r| r.name.as_deref()))
        .unwrap_or("Imported from GPX")
        .to_string();

    let description = gpx
        .metadata
        .as_ref()
        .and_then(|m| m.description.as_deref())
        .or_else(|| gpx.tracks.first().and_then(|t| t.description.as_deref()))
        .or_else(|| gpx.routes.first().and_then(|r| r.description.as_deref()))
        .map(String::from);

    let mut extras = std::collections::HashMap::new();
    if let Some(route_type) = gpx
        .routes
        .first()
        .and_then(|r| r.type_.as_deref())
        .or_else(|| gpx.tracks.first().and_then(|t| t.type_.as_deref()))
    {
        extras.insert(
            "type".to_string(),
            serde_json::Value::String(route_type.to_string()),
        );
    }
    if let Some(comment) = gpx
        .routes
        .first()
        .and_then(|r| r.comment.as_deref())
        .or_else(|| gpx.tracks.first().and_then(|t| t.comment.as_deref()))
    {
        extras.insert(
            "comment".to_string(),
            serde_json::Value::String(comment.to_string()),
        );
    }

    let waypoints: Vec<Waypoint> = if !gpx.routes.is_empty() && gpx.routes[0].points.len() >= 2 {
        let rte = &gpx.routes[0];
        rte.points
            .iter()
            .enumerate()
            .map(|(i, wpt)| {
                let pt = wpt.point();
                let (lat, lon) = (pt.y(), pt.x());
                let kind = if i == 0 {
                    WaypointKind::Start
                } else if i == rte.points.len() - 1 {
                    WaypointKind::Stop
                } else {
                    WaypointKind::Via
                };
                Waypoint {
                    id: WaypointId::new(),
                    coordinate: Coordinate::new(lat, lon),
                    kind,
                    radius_m: None,
                    name: wpt.name.clone(),
                    description: wpt.description.clone(),
                    role: None,
                    category: None,
                    geometry_ref: None,
                }
            })
            .collect()
    } else {
        vec![
            Waypoint {
                id: WaypointId::new(),
                coordinate: Coordinate::new(points[0].0, points[0].1),
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
                coordinate: Coordinate::new(points[points.len() - 1].0, points[points.len() - 1].1),
                kind: WaypointKind::Stop,
                radius_m: None,
                name: None,
                description: None,
                role: None,
                category: None,
                geometry_ref: None,
            },
        ]
    };

    let now = Utc::now();
    let route = Route {
        schema_version: Route::CURRENT_SCHEMA_VERSION,
        id: crate::RouteId::new(),
        metadata: RouteMetadata {
            name: name.clone(),
            description,
            created_at: now,
            updated_at: now,
            total_distance_m: Some(total_distance_m),
            estimated_duration_s,
            tags: vec!["gpx".to_string()],
            source: Some(ImportSource {
                format: "gpx".to_string(),
                creator: gpx.creator.clone(),
                imported_at: now,
                original_name: Some(name),
                extras,
            }),
        },
        segments: vec![RouteSegment {
            id: SegmentId::new(),
            intent: SegmentIntent::FixedGeometry,
            geometry: RouteGeometry {
                polyline: EncodedPolyline(polyline_str),
                source: GeometrySource::ImportedExact,
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
