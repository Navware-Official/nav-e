use crate::domain::{entities::*, value_objects::Position};
/// Data Transfer Objects (DTOs) for Flutter <-> Rust boundary
///
/// These DTOs define the serialization format for complex types
/// passed across the FFI boundary via JSON.
use nav_ir::Route as NavIrRoute;
use serde::{Deserialize, Serialize};

// ============================================================================
// Route DTOs
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RouteDto {
    pub id: String,
    pub waypoints: Vec<WaypointDto>,
    pub distance_meters: f64,
    pub duration_seconds: u32,
    pub polyline_json: String, // JSON array of [lat, lon]
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WaypointDto {
    pub latitude: f64,
    pub longitude: f64,
    pub name: Option<String>,
}

// ============================================================================
// Navigation DTOs
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NavigationSessionDto {
    pub id: String,
    pub route: RouteDto,
    pub current_latitude: f64,
    pub current_longitude: f64,
    pub status: String, // "Active", "Paused", "Completed", "Cancelled"
}

// ============================================================================
// Geocoding DTOs
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeocodingResultDto {
    pub latitude: f64,
    pub longitude: f64,
    pub display_name: String,
    pub name: Option<String>,
    pub city: Option<String>,
    pub country: Option<String>,
    pub osm_type: Option<String>,
    pub osm_id: Option<i64>,
}

// ============================================================================
// Conversion Functions (Internal - not exposed to FFI)
// ============================================================================

/// Convert Nav-IR Route to RouteDto
pub(crate) fn route_to_dto(route: &NavIrRoute) -> RouteDto {
    let waypoints: Vec<WaypointDto> = route
        .segments
        .iter()
        .flat_map(|s| s.waypoints.iter())
        .map(nav_ir_waypoint_to_dto)
        .collect();

    let polyline_coords: Vec<[f64; 2]> = route
        .segments
        .first()
        .and_then(|seg| polyline::decode_polyline(&seg.geometry.polyline.0, 5).ok())
        .map(|line| line.coords().map(|c| [c.y, c.x]).collect())
        .unwrap_or_default();

    let distance_meters = route.metadata.total_distance_m.unwrap_or(0.0);
    let duration_seconds = route
        .metadata
        .estimated_duration_s
        .map(|s| s as u32)
        .unwrap_or(0);

    RouteDto {
        id: route.id.0.to_string(),
        waypoints,
        distance_meters,
        duration_seconds,
        polyline_json: serde_json::to_string(&polyline_coords).unwrap_or_else(|_| "[]".to_string()),
    }
}

/// Convert Nav-IR Waypoint to WaypointDto
fn nav_ir_waypoint_to_dto(wp: &nav_ir::Waypoint) -> WaypointDto {
    WaypointDto {
        latitude: wp.coordinate.latitude,
        longitude: wp.coordinate.longitude,
        name: None,
    }
}

/// Convert NavigationSession to NavigationSessionDto
pub(crate) fn navigation_session_to_dto(session: &NavigationSession) -> NavigationSessionDto {
    let status = match session.status {
        NavigationStatus::Active => "Active",
        NavigationStatus::Paused => "Paused",
        NavigationStatus::Completed => "Completed",
        NavigationStatus::Cancelled => "Cancelled",
    };

    NavigationSessionDto {
        id: session.id.to_string(),
        route: route_to_dto(&session.route),
        current_latitude: session.current_position.latitude,
        current_longitude: session.current_position.longitude,
        status: status.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;
    use nav_ir::{
        EncodedPolyline, RouteGeometry, RouteMetadata, RouteSegment, SegmentIntent,
        Waypoint as NavIrWaypoint, WaypointId, WaypointKind,
    };
    use uuid::Uuid;

    #[test]
    fn test_route_to_dto() {
        let route = NavIrRoute {
            schema_version: NavIrRoute::CURRENT_SCHEMA_VERSION,
            id: nav_ir::RouteId::new(),
            metadata: RouteMetadata {
                name: String::new(),
                description: None,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                total_distance_m: Some(4489000.0),
                estimated_duration_s: Some(144000),
                tags: vec![],
            },
            segments: vec![RouteSegment {
                id: nav_ir::SegmentId::new(),
                intent: SegmentIntent::Recalculatable,
                geometry: RouteGeometry {
                    polyline: EncodedPolyline(
                        polyline::encode_coordinates(
                            vec![
                                geo_types::Coord {
                                    x: -74.0060,
                                    y: 40.7128,
                                },
                                geo_types::Coord {
                                    x: -118.2437,
                                    y: 34.0522,
                                },
                            ],
                            5,
                        )
                        .unwrap(),
                    ),
                    source: nav_ir::GeometrySource::SnappedToGraph,
                    confidence: nav_ir::GeometryConfidence::High,
                    bounding_box: nav_ir::BoundingBox {
                        min_lat: 34.0522,
                        min_lon: -118.2437,
                        max_lat: 40.7128,
                        max_lon: -74.0060,
                    },
                },
                waypoints: vec![
                    NavIrWaypoint {
                        id: WaypointId::new(),
                        coordinate: nav_ir::Coordinate::new(40.7128, -74.0060),
                        kind: WaypointKind::Start,
                        radius_m: None,
                    },
                    NavIrWaypoint {
                        id: WaypointId::new(),
                        coordinate: nav_ir::Coordinate::new(34.0522, -118.2437),
                        kind: WaypointKind::Stop,
                        radius_m: None,
                    },
                ],
                instructions: vec![],
                constraints: nav_ir::SegmentConstraints::default(),
            }],
            policies: nav_ir::RoutePolicies::default(),
        };

        let dto = route_to_dto(&route);
        assert_eq!(dto.waypoints.len(), 2);
        assert_eq!(dto.distance_meters, 4489000.0);
        assert_eq!(dto.duration_seconds, 144000);
        assert!(dto.polyline_json.contains("40.7128"));
    }

    #[test]
    fn test_navigation_session_to_dto() {
        let route = NavIrRoute {
            schema_version: NavIrRoute::CURRENT_SCHEMA_VERSION,
            id: nav_ir::RouteId::new(),
            metadata: RouteMetadata {
                name: String::new(),
                description: None,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                total_distance_m: Some(1000.0),
                estimated_duration_s: Some(60),
                tags: vec![],
            },
            segments: vec![],
            policies: nav_ir::RoutePolicies::default(),
        };

        let session = NavigationSession {
            id: Uuid::new_v4(),
            route,
            current_position: Position::new(40.7128, -74.0060).unwrap(),
            status: NavigationStatus::Active,
            started_at: Utc::now(),
            updated_at: Utc::now(),
        };

        let dto = navigation_session_to_dto(&session);
        assert_eq!(dto.status, "Active");
        assert_eq!(dto.current_latitude, 40.7128);
        assert_eq!(dto.current_longitude, -74.0060);
    }
}
