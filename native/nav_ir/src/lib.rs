//! Navigation Intermediate Representation (Nav-IR).
//!
//! Canonical, engine-agnostic route format. No dependency on device_comm or nav_core.
//! Use the `adapters` module to normalize OSRM, GPX, or custom API output into Nav-IR.

mod adapters;
mod types;

pub use adapters::{normalize_custom, normalize_gpx, normalize_graphhopper, normalize_osrm, OsrmResponse};
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

    fn roundtrip_fixture(json: &str) -> Route {
        let route: Route = serde_json::from_str(json).unwrap();
        route.validate().unwrap();
        let json2 = serde_json::to_string(&route).unwrap();
        let route2: Route = serde_json::from_str(&json2).unwrap();
        assert_eq!(route.schema_version, route2.schema_version);
        assert_eq!(route.metadata.name, route2.metadata.name);
        assert_eq!(route.segments.len(), route2.segments.len());
        for (i, (s1, s2)) in route.segments.iter().zip(route2.segments.iter()).enumerate() {
            assert_eq!(s1.intent, s2.intent, "segment {}", i);
            assert_eq!(s1.waypoints.len(), s2.waypoints.len(), "segment {}", i);
            assert_eq!(s1.geometry.bounding_box.min_lat, s2.geometry.bounding_box.min_lat);
            assert_eq!(s1.geometry.bounding_box.max_lon, s2.geometry.bounding_box.max_lon);
        }
        route2
    }

    #[test]
    fn fixture_minimal_roundtrip_and_validate() {
        let route = roundtrip_fixture(include_str!("../fixtures/minimal.json"));
        assert_eq!(route.metadata.name, "Minimal route");
        assert_eq!(route.segments.len(), 1);
        assert_eq!(route.segments[0].waypoints.len(), 2);
    }

    #[test]
    fn fixture_osrm_like_roundtrip_and_validate() {
        let route = roundtrip_fixture(include_str!("../fixtures/osrm_like.json"));
        assert_eq!(route.metadata.name, "Berlin to Munich");
        assert_eq!(route.segments.len(), 1);
        assert_eq!(route.segments[0].waypoints.len(), 3);
        assert_eq!(route.segments[0].intent, SegmentIntent::Recalculatable);
    }

    #[test]
    fn fixture_gpx_like_roundtrip_and_validate() {
        let route = roundtrip_fixture(include_str!("../fixtures/gpx_like.json"));
        assert_eq!(route.metadata.name, "Imported track from GPX");
        assert_eq!(route.segments.len(), 1);
        assert_eq!(route.segments[0].intent, SegmentIntent::FixedGeometry);
    }

    #[test]
    fn validate_rejects_empty_segments() {
        let route = Route {
            schema_version: Route::CURRENT_SCHEMA_VERSION,
            id: RouteId::new(),
            metadata: RouteMetadata {
                name: String::new(),
                description: None,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                total_distance_m: None,
                estimated_duration_s: None,
                tags: vec![],
            },
            segments: vec![],
            policies: RoutePolicies::default(),
        };
        assert!(matches!(
            route.validate(),
            Err(ValidationError::EmptySegments)
        ));
    }

    #[test]
    fn validate_rejects_segment_without_start_stop() {
        let route = Route {
            schema_version: Route::CURRENT_SCHEMA_VERSION,
            id: RouteId::new(),
            metadata: RouteMetadata {
                name: String::new(),
                description: None,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                total_distance_m: None,
                estimated_duration_s: None,
                tags: vec![],
            },
            segments: vec![RouteSegment {
                id: SegmentId::new(),
                intent: SegmentIntent::Recalculatable,
                geometry: RouteGeometry {
                    polyline: EncodedPolyline(String::new()),
                    source: GeometrySource::SnappedToGraph,
                    confidence: GeometryConfidence::High,
                    bounding_box: BoundingBox {
                        min_lat: 0.0,
                        min_lon: 0.0,
                        max_lat: 1.0,
                        max_lon: 1.0,
                    },
                },
                waypoints: vec![Waypoint {
                    id: WaypointId::new(),
                    coordinate: Coordinate::new(0.5, 0.5),
                    kind: WaypointKind::Via,
                    radius_m: None,
                }],
                instructions: vec![],
                constraints: SegmentConstraints::default(),
            }],
            policies: RoutePolicies::default(),
        };
        assert!(matches!(
            route.validate(),
            Err(ValidationError::SegmentMissingStartOrStop { segment_index: 0 })
        ));
    }

    #[test]
    fn validate_rejects_invalid_bounding_box() {
        let route = Route {
            schema_version: Route::CURRENT_SCHEMA_VERSION,
            id: RouteId::new(),
            metadata: RouteMetadata {
                name: String::new(),
                description: None,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                total_distance_m: None,
                estimated_duration_s: None,
                tags: vec![],
            },
            segments: vec![RouteSegment {
                id: SegmentId::new(),
                intent: SegmentIntent::Recalculatable,
                geometry: RouteGeometry {
                    polyline: EncodedPolyline(String::new()),
                    source: GeometrySource::SnappedToGraph,
                    confidence: GeometryConfidence::High,
                    bounding_box: BoundingBox {
                        min_lat: 2.0,
                        min_lon: 0.0,
                        max_lat: 1.0,
                        max_lon: 1.0,
                    },
                },
                waypoints: vec![
                    Waypoint {
                        id: WaypointId::new(),
                        coordinate: Coordinate::new(0.5, 0.5),
                        kind: WaypointKind::Start,
                        radius_m: None,
                    },
                    Waypoint {
                        id: WaypointId::new(),
                        coordinate: Coordinate::new(1.5, 1.5),
                        kind: WaypointKind::Stop,
                        radius_m: None,
                    },
                ],
                instructions: vec![],
                constraints: SegmentConstraints::default(),
            }],
            policies: RoutePolicies::default(),
        };
        assert!(matches!(
            route.validate(),
            Err(ValidationError::InvalidBoundingBox { segment_index: 0 })
        ));
    }

    #[test]
    fn validate_rejects_unsupported_schema_version() {
        let mut route = Route {
            schema_version: Route::CURRENT_SCHEMA_VERSION,
            id: RouteId::new(),
            metadata: RouteMetadata {
                name: String::new(),
                description: None,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                total_distance_m: None,
                estimated_duration_s: None,
                tags: vec![],
            },
            segments: vec![RouteSegment {
                id: SegmentId::new(),
                intent: SegmentIntent::Recalculatable,
                geometry: RouteGeometry {
                    polyline: EncodedPolyline(String::new()),
                    source: GeometrySource::SnappedToGraph,
                    confidence: GeometryConfidence::High,
                    bounding_box: BoundingBox {
                        min_lat: 0.0,
                        min_lon: 0.0,
                        max_lat: 1.0,
                        max_lon: 1.0,
                    },
                },
                waypoints: vec![
                    Waypoint {
                        id: WaypointId::new(),
                        coordinate: Coordinate::new(0.0, 0.0),
                        kind: WaypointKind::Start,
                        radius_m: None,
                    },
                    Waypoint {
                        id: WaypointId::new(),
                        coordinate: Coordinate::new(1.0, 1.0),
                        kind: WaypointKind::Stop,
                        radius_m: None,
                    },
                ],
                instructions: vec![],
                constraints: SegmentConstraints::default(),
            }],
            policies: RoutePolicies::default(),
        };
        route.schema_version = 99;
        assert!(matches!(
            route.validate(),
            Err(ValidationError::UnsupportedSchemaVersion(99))
        ));
    }
}
