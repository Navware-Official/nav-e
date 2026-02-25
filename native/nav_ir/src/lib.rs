//! Navigation Intermediate Representation (Nav-IR).
//!
//! Canonical, engine-agnostic route format. No dependency on device_comm or nav_core.

mod types;

pub use types::*;

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;

    #[test]
    fn minimal_route_construction_and_serialization() {
        let now = Utc::now();
        let route = Route {
            schema_version: Route::CURRENT_SCHEMA_VERSION,
            id: RouteId::new(),
            metadata: RouteMetadata {
                name: "Test route".into(),
                description: None,
                created_at: now,
                updated_at: now,
                total_distance_m: Some(5000.0),
                estimated_duration_s: Some(600),
                tags: vec![],
            },
            segments: vec![RouteSegment {
                id: SegmentId::new(),
                intent: SegmentIntent::Recalculatable,
                geometry: RouteGeometry {
                    polyline: EncodedPolyline("_p~iF~ps|U_ulLnnqC_mqNvxq`@".into()),
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
                        coordinate: Coordinate::new(40.7128, -74.0060),
                        kind: WaypointKind::Start,
                        radius_m: None,
                    },
                    Waypoint {
                        id: WaypointId::new(),
                        coordinate: Coordinate::new(40.7580, -73.9855),
                        kind: WaypointKind::Stop,
                        radius_m: None,
                    },
                ],
                instructions: vec![],
                constraints: SegmentConstraints::default(),
            }],
            policies: RoutePolicies::default(),
        };

        let json = serde_json::to_string(&route).unwrap();
        assert!(json.contains("Test route"));
        assert!(json.contains("Recalculatable"));

        let roundtrip: Route = serde_json::from_str(&json).unwrap();
        assert_eq!(roundtrip.schema_version, route.schema_version);
        assert_eq!(roundtrip.metadata.name, route.metadata.name);
        assert_eq!(roundtrip.segments.len(), 1);
        assert_eq!(roundtrip.segments[0].waypoints.len(), 2);
    }
}
