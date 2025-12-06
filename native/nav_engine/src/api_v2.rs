/// Modern FRB API - Direct exposure of DDD/Hexagonal architecture
/// 
/// This module provides the flutter_rust_bridge API surface for the new architecture.
/// Clean, type-safe, and follows domain-driven design principles.

use anyhow::Result;
use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use std::sync::Arc;

use crate::application::{commands::*, handlers::*, queries::*};
use crate::domain::{entities::*, ports::*, value_objects::*};
use crate::infrastructure::{
    geocoding_adapter::PhotonGeocodingService,
    in_memory_repo::InMemoryNavigationRepository,
    osrm_adapter::OsrmRouteService,
};

// Re-export traits for frb_generated.rs
pub use crate::domain::ports::{
    DeviceCommunicationPort,
    GeocodingService, NavigationRepository, RouteService,
};
pub use crate::infrastructure::protobuf_adapter::DeviceTransport;

// ============================================================================
// DTOs for Flutter <-> Rust boundary
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NavigationSessionDto {
    pub id: String,
    pub route: RouteDto,
    pub current_latitude: f64,
    pub current_longitude: f64,
    pub status: String, // "Active", "Paused", "Completed", "Cancelled"
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeocodingResultDto {
    pub latitude: f64,
    pub longitude: f64,
    pub display_name: String,
}

// ============================================================================
// Global Application Context
// ============================================================================

pub struct AppContext {
    pub route_service: Arc<dyn RouteService>,
    pub geocoding_service: Arc<dyn GeocodingService>,
    pub navigation_repo: Arc<dyn NavigationRepository>,
}

impl AppContext {
    pub fn new() -> Self {
        Self {
            route_service: Arc::new(OsrmRouteService::new(
                "https://router.project-osrm.org".to_string(),
            )),
            geocoding_service: Arc::new(PhotonGeocodingService::new(
                "https://photon.komoot.io".to_string(),
            )),
            navigation_repo: Arc::new(InMemoryNavigationRepository::new()),
        }
    }
}

use std::sync::OnceLock;
static APP_CONTEXT: OnceLock<AppContext> = OnceLock::new();

fn get_context() -> &'static AppContext {
    APP_CONTEXT.get_or_init(AppContext::new)
}

// ============================================================================
// Route APIs
// ============================================================================

/// Calculate a route between waypoints
#[frb]
pub fn calculate_route(waypoints: Vec<(f64, f64)>) -> Result<String> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async {
        let ctx = get_context();
        let handler = CalculateRouteHandler::new(ctx.route_service.clone());

        let positions: Result<Vec<Position>> = waypoints
            .into_iter()
            .map(|(lat, lon)| Position::new(lat, lon).map_err(|e| anyhow::anyhow!(e)))
            .collect();

        let query = CalculateRouteQuery {
            waypoints: positions?,
        };

        let route = handler.handle(query).await?;
        let dto = route_to_dto(route);
        Ok(serde_json::to_string(&dto)?)
    })
}

/// Start a new navigation session
#[frb]
pub fn start_navigation_session(
    waypoints: Vec<(f64, f64)>,
    current_position: (f64, f64),
) -> Result<String> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async {
        let ctx = get_context();

        let waypoint_positions: Result<Vec<Position>> = waypoints
            .into_iter()
            .map(|(lat, lon)| Position::new(lat, lon).map_err(|e| anyhow::anyhow!(e)))
            .collect();

        let current_pos =
            Position::new(current_position.0, current_position.1).map_err(|e| anyhow::anyhow!(e))?;

        let device_comm = Arc::new(MockDeviceComm);

        let handler = StartNavigationHandler::new(
            ctx.route_service.clone(),
            ctx.navigation_repo.clone(),
            device_comm,
        );

        let command = StartNavigationCommand {
            waypoints: waypoint_positions?,
            current_position: current_pos,
            device_id: None,
        };

        let session = handler.handle(command).await?;
        let dto = session_to_dto(session);
        Ok(serde_json::to_string(&dto)?)
    })
}

/// Update current position during navigation
#[frb]
pub fn update_navigation_position(session_id: String, latitude: f64, longitude: f64) -> Result<()> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async {
        let ctx = get_context();
        let handler =
            UpdatePositionHandler::new(ctx.navigation_repo.clone(), Arc::new(MockDeviceComm));

        let position = Position::new(latitude, longitude).map_err(|e| anyhow::anyhow!(e))?;
        let session_uuid = uuid::Uuid::parse_str(&session_id)?;

        let command = UpdatePositionCommand {
            session_id: session_uuid,
            position,
        };

        handler.handle(command).await?;
        Ok(())
    })
}

/// Get the currently active navigation session
#[frb]
pub fn get_active_session() -> Result<Option<String>> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async {
        let ctx = get_context();
        let handler = GetActiveSessionHandler::new(ctx.navigation_repo.clone());

        let session = handler.handle(GetActiveSessionQuery {}).await?;
        Ok(session.map(|s| serde_json::to_string(&session_to_dto(s)).unwrap()))
    })
}

/// Pause active navigation
#[frb]
pub fn pause_navigation(session_id: String) -> Result<()> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async {
        let ctx = get_context();
        let handler = PauseNavigationHandler::new(ctx.navigation_repo.clone());

        let session_uuid = uuid::Uuid::parse_str(&session_id)?;
        let command = PauseNavigationCommand {
            session_id: session_uuid,
        };

        handler.handle(command).await?;
        Ok(())
    })
}

/// Resume paused navigation
#[frb]
pub fn resume_navigation(session_id: String) -> Result<()> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async {
        let ctx = get_context();
        let handler = ResumeNavigationHandler::new(ctx.navigation_repo.clone());

        let session_uuid = uuid::Uuid::parse_str(&session_id)?;
        let command = ResumeNavigationCommand {
            session_id: session_uuid,
        };

        handler.handle(command).await?;
        Ok(())
    })
}

/// Stop/complete navigation
#[frb]
pub fn stop_navigation(session_id: String, completed: bool) -> Result<()> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async {
        let ctx = get_context();
        let handler = StopNavigationHandler::new(ctx.navigation_repo.clone());

        let session_uuid = uuid::Uuid::parse_str(&session_id)?;
        let command = StopNavigationCommand {
            session_id: session_uuid,
            completed,
        };

        handler.handle(command).await?;
        Ok(())
    })
}

// ============================================================================
// Geocoding APIs
// ============================================================================

/// Search for locations by address/name
#[frb]
pub fn geocode_search(query: String, limit: Option<u32>) -> Result<String> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async {
        let ctx = get_context();
        let handler = GeocodeHandler::new(ctx.geocoding_service.clone());

        let geocode_query = GeocodeQuery { address: query };
        let positions = handler.handle(geocode_query).await?;

        let results: Vec<GeocodingResultDto> = positions
            .into_iter()
            .take(limit.unwrap_or(10) as usize)
            .map(|pos| GeocodingResultDto {
                latitude: pos.latitude,
                longitude: pos.longitude,
                display_name: format!("{:.4}, {:.4}", pos.latitude, pos.longitude),
            })
            .collect();

        Ok(serde_json::to_string(&results)?)
    })
}

/// Reverse geocode coordinates to address
#[frb]
pub fn reverse_geocode(latitude: f64, longitude: f64) -> Result<String> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    rt.block_on(async {
        let ctx = get_context();
        let handler = ReverseGeocodeHandler::new(ctx.geocoding_service.clone());

        let position = Position::new(latitude, longitude).map_err(|e| anyhow::anyhow!(e))?;
        let query = ReverseGeocodeQuery { position };

        let address = handler.handle(query).await?;
        Ok(address)
    })
}

// ============================================================================
// Utility Functions
// ============================================================================

fn route_to_dto(route: Route) -> RouteDto {
    let polyline_coords: Vec<[f64; 2]> = route
        .polyline
        .iter()
        .map(|p| [p.latitude, p.longitude])
        .collect();

    RouteDto {
        id: route.id.to_string(),
        waypoints: route
            .waypoints
            .iter()
            .map(|w| WaypointDto {
                latitude: w.position.latitude,
                longitude: w.position.longitude,
                name: w.name.clone(),
            })
            .collect(),
        distance_meters: route.distance_meters,
        duration_seconds: route.duration_seconds,
        polyline_json: serde_json::to_string(&polyline_coords).unwrap_or_default(),
    }
}

fn session_to_dto(session: NavigationSession) -> NavigationSessionDto {
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

// Mock implementations for device communication (temporary)
struct MockDeviceComm;

#[async_trait::async_trait]
impl DeviceCommunicationPort for MockDeviceComm {
    async fn send_route_summary(&self, _device_id: String, _session: &NavigationSession) -> Result<()> {
        Ok(())
    }

    async fn send_route_blob(&self, _device_id: String, _route: &Route) -> Result<()> {
        Ok(())
    }

    async fn send_position_update(&self, _device_id: String, _position: Position) -> Result<()> {
        Ok(())
    }

    async fn send_traffic_alert(&self, _device_id: String, _event: &TrafficEvent) -> Result<()> {
        Ok(())
    }

    async fn send_control_command(&self, _device_id: String, _command: ControlCommand) -> Result<()> {
        Ok(())
    }
}
