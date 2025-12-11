/// Data Transfer Objects (DTOs) for Flutter <-> Rust boundary
/// 
/// These DTOs define the serialization format for complex types
/// passed across the FFI boundary via JSON.

use serde::{Deserialize, Serialize};
use crate::domain::{entities::*, value_objects::*};

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

/// Convert Route to RouteDto
pub(crate) fn route_to_dto(route: Route) -> RouteDto {
    let polyline_coords: Vec<[f64; 2]> = route
        .polyline
        .iter()
        .map(|p| [p.latitude, p.longitude])
        .collect();

    RouteDto {
        id: route.id.to_string(),
        waypoints: route
            .waypoints
            .into_iter()
            .map(waypoint_to_dto)
            .collect(),
        distance_meters: route.distance_meters,
        duration_seconds: route.duration_seconds,
        polyline_json: serde_json::to_string(&polyline_coords)
            .unwrap_or_else(|_| "[]".to_string()),
    }
}

/// Convert Waypoint to WaypointDto
pub(crate) fn waypoint_to_dto(waypoint: Waypoint) -> WaypointDto {
    WaypointDto {
        latitude: waypoint.position.latitude,
        longitude: waypoint.position.longitude,
        name: waypoint.name,
    }
}

/// Convert NavigationSession to NavigationSessionDto
pub(crate) fn navigation_session_to_dto(session: NavigationSession) -> NavigationSessionDto {
    let status = match session.status {
        NavigationStatus::Active => "Active",
        NavigationStatus::Paused => "Paused",
        NavigationStatus::Completed => "Completed",
        NavigationStatus::Cancelled => "Cancelled",
    };

    NavigationSessionDto {
        id: session.id.to_string(),
        route: route_to_dto(session.route),
        current_latitude: session.current_position.latitude,
        current_longitude: session.current_position.longitude,
        status: status.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;
    use uuid::Uuid;

    #[test]
    fn test_route_to_dto() {
        let route = Route {
            id: Uuid::new_v4(),
            waypoints: vec![
                Waypoint {
                    position: Position::new(40.7128, -74.0060).unwrap(),
                    name: Some("Start".to_string()),
                },
                Waypoint {
                    position: Position::new(34.0522, -118.2437).unwrap(),
                    name: Some("End".to_string()),
                },
            ],
            polyline: vec![
                Position::new(40.7128, -74.0060).unwrap(),
                Position::new(34.0522, -118.2437).unwrap(),
            ],
            distance_meters: 4489000.0,
            duration_seconds: 144000,
            created_at: Utc::now(),
        };

        let dto = route_to_dto(route);
        assert_eq!(dto.waypoints.len(), 2);
        assert_eq!(dto.distance_meters, 4489000.0);
        assert_eq!(dto.duration_seconds, 144000);
        assert!(dto.polyline_json.contains("40.7128"));
    }

    #[test]
    fn test_navigation_session_to_dto() {
        let route = Route {
            id: Uuid::new_v4(),
            waypoints: vec![],
            polyline: vec![],
            distance_meters: 1000.0,
            duration_seconds: 60,
            created_at: Utc::now(),
        };

        let session = NavigationSession {
            id: Uuid::new_v4(),
            route,
            current_position: Position::new(40.7128, -74.0060).unwrap(),
            status: NavigationStatus::Active,
            started_at: Utc::now(),
            updated_at: Utc::now(),
        };

        let dto = navigation_session_to_dto(session);
        assert_eq!(dto.status, "Active");
        assert_eq!(dto.current_latitude, 40.7128);
        assert_eq!(dto.current_longitude, -74.0060);
    }
}
