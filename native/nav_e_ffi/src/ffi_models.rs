/// FRB-visible Data Transfer Objects
///
/// These structs are defined in `nav_e_ffi` so that FRB codegen generates
/// transparent Dart classes with accessible fields. Types defined in external
/// crates (e.g. `nav_core::api::dto`) are treated as opaque by FRB and cannot
/// have their fields accessed in Dart.

use flutter_rust_bridge::frb;

// ============================================================================
// Navigation State
// ============================================================================

#[frb]
#[derive(Debug, Clone)]
pub struct NavigationStateDto {
    pub current_step: u32,
    pub current_instruction: DerivedInstructionDto,
    pub next_instruction: Option<DerivedInstructionDto>,
    pub distance_to_next_m: f64,
    pub distance_remaining_m: f64,
    pub eta_seconds: u64,
    pub is_off_route: bool,
    pub distance_from_route_m: f64,
    pub snapped_lat: f64,
    pub snapped_lon: f64,
    pub constraint_alerts: Vec<String>,
}

#[frb]
#[derive(Debug, Clone)]
pub struct DerivedInstructionDto {
    pub kind: String,
    pub distance_to_next_m: f64,
    pub street_name: Option<String>,
}

// ============================================================================
// Route
// ============================================================================

#[frb]
#[derive(Debug, Clone)]
pub struct RouteDto {
    pub id: String,
    pub waypoints: Vec<WaypointDto>,
    pub distance_meters: f64,
    pub duration_seconds: u32,
    pub polyline_json: String,
}

#[frb]
#[derive(Debug, Clone)]
pub struct WaypointDto {
    pub latitude: f64,
    pub longitude: f64,
    pub name: Option<String>,
}

// ============================================================================
// Navigation Session
// ============================================================================

#[frb]
#[derive(Debug, Clone)]
pub struct NavigationSessionDto {
    pub id: String,
    pub route: RouteDto,
    pub current_latitude: f64,
    pub current_longitude: f64,
    pub status: String,
}

// ============================================================================
// Session Stats
// ============================================================================

#[frb]
#[derive(Debug, Clone)]
pub struct SessionStatsDto {
    pub total_distance_m: f64,
    pub total_duration_seconds: i64,
    pub session_count: i64,
}

// ============================================================================
// Geocoding
// ============================================================================

#[frb]
#[derive(Debug, Clone)]
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
// Conversions from nav_core DTOs
// ============================================================================

impl From<nav_core::api::dto::DerivedInstructionDto> for DerivedInstructionDto {
    fn from(d: nav_core::api::dto::DerivedInstructionDto) -> Self {
        Self {
            kind: d.kind,
            distance_to_next_m: d.distance_to_next_m,
            street_name: d.street_name,
        }
    }
}

impl From<nav_core::api::dto::NavigationStateDto> for NavigationStateDto {
    fn from(s: nav_core::api::dto::NavigationStateDto) -> Self {
        Self {
            current_step: s.current_step,
            current_instruction: s.current_instruction.into(),
            next_instruction: s.next_instruction.map(Into::into),
            distance_to_next_m: s.distance_to_next_m,
            distance_remaining_m: s.distance_remaining_m,
            eta_seconds: s.eta_seconds,
            is_off_route: s.is_off_route,
            distance_from_route_m: s.distance_from_route_m,
            snapped_lat: s.snapped_lat,
            snapped_lon: s.snapped_lon,
            constraint_alerts: s.constraint_alerts,
        }
    }
}

impl From<nav_core::api::dto::WaypointDto> for WaypointDto {
    fn from(w: nav_core::api::dto::WaypointDto) -> Self {
        Self {
            latitude: w.latitude,
            longitude: w.longitude,
            name: w.name,
        }
    }
}

impl From<nav_core::api::dto::RouteDto> for RouteDto {
    fn from(r: nav_core::api::dto::RouteDto) -> Self {
        Self {
            id: r.id,
            waypoints: r.waypoints.into_iter().map(Into::into).collect(),
            distance_meters: r.distance_meters,
            duration_seconds: r.duration_seconds,
            polyline_json: r.polyline_json,
        }
    }
}

impl From<nav_core::api::dto::NavigationSessionDto> for NavigationSessionDto {
    fn from(s: nav_core::api::dto::NavigationSessionDto) -> Self {
        Self {
            id: s.id,
            route: s.route.into(),
            current_latitude: s.current_latitude,
            current_longitude: s.current_longitude,
            status: s.status,
        }
    }
}

impl From<nav_core::api::dto::SessionStatsDto> for SessionStatsDto {
    fn from(s: nav_core::api::dto::SessionStatsDto) -> Self {
        Self {
            total_distance_m: s.total_distance_m,
            total_duration_seconds: s.total_duration_seconds,
            session_count: s.session_count,
        }
    }
}

impl From<nav_core::api::dto::GeocodingResultDto> for GeocodingResultDto {
    fn from(g: nav_core::api::dto::GeocodingResultDto) -> Self {
        Self {
            latitude: g.latitude,
            longitude: g.longitude,
            display_name: g.display_name,
            name: g.name,
            city: g.city,
            country: g.country,
            osm_type: g.osm_type,
            osm_id: g.osm_id,
        }
    }
}
