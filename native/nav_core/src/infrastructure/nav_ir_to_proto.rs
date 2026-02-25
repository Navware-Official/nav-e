//! Convert Nav-IR Route to device_comm proto RouteBlob (single path for device send).

use anyhow::Result;
use device_comm::proto;
use nav_ir::{Route, WaypointKind};
use sha2::{Digest, Sha256};

/// Build a RouteBlob from a Nav-IR Route. Uses first segment's geometry and flattens waypoints.
pub fn nav_ir_route_to_route_blob(
    route: &Route,
    header: proto::Header,
) -> Result<proto::RouteBlob> {
    let route_id_bytes = route.id.0.as_bytes().to_vec();

    // Flatten waypoints from all segments (order preserved)
    let mut index = 0u32;
    let proto_waypoints: Vec<proto::Waypoint> = route
        .segments
        .iter()
        .flat_map(|seg| &seg.waypoints)
        .map(|wp| {
            let name = match &wp.kind {
                WaypointKind::Start => "Start".to_string(),
                WaypointKind::Stop => "Stop".to_string(),
                WaypointKind::Via => format!("Via {}", index),
                _ => format!("Waypoint {}", index),
            };
            index += 1;
            proto::Waypoint {
                lat: wp.coordinate.latitude,
                lon: wp.coordinate.longitude,
                name,
                index: index - 1,
            }
        })
        .collect();

    // Use first segment's polyline; if multiple segments, use first only (simplified)
    let encoded_polyline = route
        .segments
        .first()
        .map(|seg| seg.geometry.polyline.0.clone())
        .unwrap_or_else(String::new);

    let mut hasher = Sha256::new();
    hasher.update(encoded_polyline.as_bytes());
    let checksum = hasher.finalize().to_vec();

    let metadata = Some(proto::Metadata {
        zoom_hint: 0,
        preferred_zoom: 0,
        total_points: 0,
        route_name: route.metadata.name.clone(),
        created_at_ms: route.metadata.created_at.timestamp_millis() as u64,
    });

    let total_distance = route
        .metadata
        .total_distance_m
        .map(|m| m as u32)
        .unwrap_or(0);
    let total_duration = route
        .metadata
        .estimated_duration_s
        .map(|s| s as u32)
        .unwrap_or(0);
    let legs: Vec<proto::RouteLeg> = if route.segments.is_empty() {
        vec![]
    } else if route.segments.len() == 1 {
        vec![proto::RouteLeg {
            distance_m: total_distance,
            duration_s: total_duration,
            summary: String::new(),
            steps: vec![],
        }]
    } else {
        route
            .segments
            .iter()
            .map(|_| proto::RouteLeg {
                distance_m: total_distance / route.segments.len() as u32,
                duration_s: total_duration / route.segments.len() as u32,
                summary: String::new(),
                steps: vec![],
            })
            .collect()
    };

    Ok(proto::RouteBlob {
        header: Some(header),
        route_id: route_id_bytes,
        waypoints: proto_waypoints,
        legs,
        polyline_data: Some(proto::route_blob::PolylineData::EncodedPolyline(
            encoded_polyline,
        )),
        metadata,
        compressed: false,
        checksum,
        signature: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;
    use nav_ir::{
        BoundingBox, EncodedPolyline, GeometryConfidence, GeometrySource, RouteGeometry,
        RouteMetadata, RoutePolicies, RouteSegment, SegmentConstraints, SegmentIntent,
        Waypoint, WaypointId, WaypointKind,
    };

    #[test]
    fn nav_ir_to_route_blob_roundtrip() {
        let route = Route {
            schema_version: Route::CURRENT_SCHEMA_VERSION,
            id: nav_ir::RouteId::new(),
            metadata: RouteMetadata {
                name: "Test".into(),
                description: None,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                total_distance_m: Some(1000.0),
                estimated_duration_s: Some(120),
                tags: vec![],
            },
            segments: vec![RouteSegment {
                id: nav_ir::SegmentId::new(),
                intent: SegmentIntent::Recalculatable,
                geometry: RouteGeometry {
                    polyline: EncodedPolyline("_p~iF~ps|U".into()),
                    source: GeometrySource::SnappedToGraph,
                    confidence: GeometryConfidence::High,
                    bounding_box: BoundingBox {
                        min_lat: 40.0,
                        min_lon: -74.0,
                        max_lat: 41.0,
                        max_lon: -73.0,
                    },
                },
                waypoints: vec![
                    Waypoint {
                        id: WaypointId::new(),
                        coordinate: nav_ir::Coordinate::new(40.71, -74.01),
                        kind: WaypointKind::Start,
                        radius_m: None,
                    },
                    Waypoint {
                        id: WaypointId::new(),
                        coordinate: nav_ir::Coordinate::new(40.76, -73.99),
                        kind: WaypointKind::Stop,
                        radius_m: None,
                    },
                ],
                instructions: vec![],
                constraints: SegmentConstraints::default(),
            }],
            policies: RoutePolicies::default(),
        };

        let header = proto::Header {
            protocol_version: 1,
            message_version: 1,
        };
        let blob = nav_ir_route_to_route_blob(&route, header).unwrap();

        assert_eq!(blob.route_id.len(), 16);
        assert_eq!(blob.waypoints.len(), 2);
        assert_eq!(blob.waypoints[0].lat, 40.71);
        assert_eq!(blob.waypoints[0].lon, -74.01);
        assert_eq!(blob.waypoints[1].lat, 40.76);
        assert_eq!(blob.waypoints[1].lon, -73.99);
        assert!(matches!(
            &blob.polyline_data,
            Some(proto::route_blob::PolylineData::EncodedPolyline(s)) if s == "_p~iF~ps|U"
        ));
        assert!(!blob.checksum.is_empty());
    }
}
