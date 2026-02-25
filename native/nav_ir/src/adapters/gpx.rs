//! GPX bytes → Nav-IR Route.
//!
//! Normalizes GPX track/route into a single Nav-IR Route (one segment, FixedGeometry, ImportedExact).

use crate::{
    BoundingBox, EncodedPolyline, GeometryConfidence, GeometrySource, Coordinate, Route,
    RouteGeometry, RouteMetadata, RoutePolicies, RouteSegment, SegmentConstraints,
    SegmentId, SegmentIntent, Waypoint, WaypointId, WaypointKind,
};
use chrono::Utc;
use geo_types::Coord;
use std::io::BufReader;

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

    let coords: Vec<Coord<f64>> = points
        .iter()
        .map(|(lat, lon)| Coord { x: *lon, y: *lat })
        .collect();
    let polyline_str =
        polyline::encode_coordinates(coords.clone(), 5).map_err(|e| format!("Polyline encode: {}", e))?;

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

    let waypoints = vec![
        Waypoint {
            id: WaypointId::new(),
            coordinate: Coordinate::new(points[0].0, points[0].1),
            kind: WaypointKind::Start,
            radius_m: None,
        },
        Waypoint {
            id: WaypointId::new(),
            coordinate: Coordinate::new(points[points.len() - 1].0, points[points.len() - 1].1),
            kind: WaypointKind::Stop,
            radius_m: None,
        },
    ];

    let now = Utc::now();
    let route = Route {
        schema_version: Route::CURRENT_SCHEMA_VERSION,
        id: crate::RouteId::new(),
        metadata: RouteMetadata {
            name,
            description: None,
            created_at: now,
            updated_at: now,
            total_distance_m: None,
            estimated_duration_s: None,
            tags: vec!["gpx".to_string()],
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
            instructions: vec![],
            constraints: SegmentConstraints::default(),
        }],
        policies: RoutePolicies::default(),
    };
    route.validate().map_err(|e| e.to_string())?;
    Ok(route)
}
