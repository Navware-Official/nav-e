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
    database::{Database, SavedPlacesRepository, DeviceRepository, SavedPlace, Device},
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
    pub name: Option<String>,
    pub city: Option<String>,
    pub country: Option<String>,
    pub osm_type: Option<String>,
    pub osm_id: Option<i64>,
}

// ============================================================================
// Global Application Context
// ============================================================================

pub struct AppContext {
    pub route_service: Arc<dyn RouteService>,
    pub geocoding_service: Arc<dyn GeocodingService>,
    pub navigation_repo: Arc<dyn NavigationRepository>,
    #[frb(ignore)]
    pub saved_places_repo: SavedPlacesRepository,
    #[frb(ignore)]
    pub device_repo: DeviceRepository,
}

impl AppContext {
    pub fn new() -> Self {
        // Initialize database
        let db_path = Self::get_db_path();
        let db = Database::new(db_path)
            .expect("Failed to initialize database");
        let db_conn = db.get_connection();
        
        Self {
            route_service: Arc::new(OsrmRouteService::new(
                "https://router.project-osrm.org".to_string(),
            )),
            geocoding_service: Arc::new(PhotonGeocodingService::new(
                "https://photon.komoot.io".to_string(),
            )),
            navigation_repo: Arc::new(InMemoryNavigationRepository::new()),
            saved_places_repo: SavedPlacesRepository::new(Arc::clone(&db_conn)),
            device_repo: DeviceRepository::new(db_conn),
        }
    }
    
    fn get_db_path() -> std::path::PathBuf {
        // Get app data directory - this will be platform-specific
        #[cfg(target_os = "android")]
        {
            // On Android, use the app's internal storage
            std::path::PathBuf::from("/data/data/org.navware.nav_e/databases/nav_e.db")
        }
        
        #[cfg(target_os = "ios")]
        {
            // On iOS, use the Documents directory
            let home = std::env::var("HOME").unwrap_or_else(|_| ".".to_string());
            std::path::PathBuf::from(format!("{}/Documents/nav_e.db", home))
        }
        
        #[cfg(not(any(target_os = "android", target_os = "ios")))]
        {
            // For desktop/testing, use current directory
            std::path::PathBuf::from("nav_e.db")
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
        // Call Photon API directly to get rich results
        let url = format!(
            "https://photon.komoot.io/api?q={}&limit={}",
            urlencoding::encode(&query),
            limit.unwrap_or(10)
        );

        let client = reqwest::Client::new();
        let response = client
            .get(&url)
            .send()
            .await
            .context("Failed to send geocoding request")?;

        let data: serde_json::Value = response
            .json()
            .await
            .context("Failed to parse geocoding response")?;

        let features = data["features"]
            .as_array()
            .context("No features in response")?;

        let results: Vec<GeocodingResultDto> = features
            .iter()
            .filter_map(|feature| {
                let coords = feature["geometry"]["coordinates"].as_array()?;
                let lon = coords.first()?.as_f64()?;
                let lat = coords.get(1)?.as_f64()?;
                
                let props = &feature["properties"];
                let name = props["name"].as_str().map(|s| s.to_string());
                let city = props["city"].as_str().map(|s| s.to_string());
                let country = props["country"].as_str().map(|s| s.to_string());
                let osm_type = props["osm_type"].as_str().map(|s| s.to_string());
                let osm_id = props["osm_id"].as_i64();
                
                // Build display name from properties
                let mut parts = Vec::new();
                if let Some(n) = props["name"].as_str() {
                    parts.push(n.to_string());
                }
                if let Some(s) = props["street"].as_str() {
                    parts.push(s.to_string());
                }
                if let Some(c) = props["city"].as_str() {
                    parts.push(c.to_string());
                }
                if let Some(co) = props["country"].as_str() {
                    parts.push(co.to_string());
                }
                let display_name = if parts.is_empty() {
                    format!("{:.4}, {:.4}", lat, lon)
                } else {
                    parts.join(", ")
                };

                Some(GeocodingResultDto {
                    latitude: lat,
                    longitude: lon,
                    display_name,
                    name,
                    city,
                    country,
                    osm_type,
                    osm_id,
                })
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

// ============================================================================
// Saved Places APIs
// ============================================================================

/// Get all saved places as JSON array
#[frb(sync)]
pub fn get_all_saved_places() -> Result<String> {
    let ctx = get_context();
    let places = ctx.saved_places_repo.get_all()?;
    let json = serde_json::to_string(&places)?;
    Ok(json)
}

/// Get a saved place by ID as JSON object
#[frb(sync)]
pub fn get_saved_place_by_id(id: i64) -> Result<String> {
    let ctx = get_context();
    let place = ctx.saved_places_repo.get_by_id(id)?;
    let json = serde_json::to_string(&place)?;
    Ok(json)
}

/// Save a new place and return the assigned ID
#[frb(sync)]
pub fn save_place(
    name: String,
    address: Option<String>,
    lat: f64,
    lon: f64,
    source: Option<String>,
    type_id: Option<i64>,
    remote_id: Option<String>,
) -> Result<i64> {
    let ctx = get_context();
    let now = chrono::Utc::now().timestamp_millis();
    
    let place = SavedPlace {
        id: None,
        type_id,
        source: source.unwrap_or_else(|| "manual".to_string()),
        remote_id,
        name,
        address,
        lat,
        lon,
        created_at: now,
    };
    
    let id = ctx.saved_places_repo.insert(place)?;
    Ok(id)
}

/// Delete a saved place by ID
#[frb(sync)]
pub fn delete_saved_place(id: i64) -> Result<()> {
    let ctx = get_context();
    ctx.saved_places_repo.delete(id)?;
    Ok(())
}

// ============================================================================
// Device Management APIs
// ============================================================================

/// Get all devices as JSON array
#[frb(sync)]
pub fn get_all_devices() -> Result<String> {
    let ctx = get_context();
    let devices = ctx.device_repo.get_all()?;
    let json = serde_json::to_string(&devices)?;
    Ok(json)
}

/// Get a device by ID as JSON object
#[frb(sync)]
pub fn get_device_by_id(id: i64) -> Result<String> {
    let ctx = get_context();
    let device = ctx.device_repo.get_by_id(id)?;
    let json = serde_json::to_string(&device)?;
    Ok(json)
}

/// Get a device by remote ID as JSON object
#[frb(sync)]
pub fn get_device_by_remote_id(remote_id: String) -> Result<String> {
    let ctx = get_context();
    let device = ctx.device_repo.get_by_remote_id(&remote_id)?;
    let json = serde_json::to_string(&device)?;
    Ok(json)
}

/// Save a new device from JSON and return the assigned ID
#[frb(sync)]
pub fn save_device(device_json: String) -> Result<i64> {
    let ctx = get_context();
    let mut device: Device = serde_json::from_str(&device_json)?;
    let now = chrono::Utc::now().timestamp_millis();
    device.created_at = now;
    device.updated_at = now;
    device.id = None; // Ensure no ID for insert
    
    let id = ctx.device_repo.insert(device)?;
    Ok(id)
}

/// Update an existing device from JSON
#[frb(sync)]
pub fn update_device(id: i64, device_json: String) -> Result<()> {
    let ctx = get_context();
    let mut device: Device = serde_json::from_str(&device_json)?;
    device.updated_at = chrono::Utc::now().timestamp_millis();
    
    ctx.device_repo.update(id, device)?;
    Ok(())
}

/// Delete a device by ID
#[frb(sync)]
pub fn delete_device(id: i64) -> Result<()> {
    let ctx = get_context();
    ctx.device_repo.delete(id)?;
    Ok(())
}

/// Check if a device exists by remote ID
#[frb(sync)]
pub fn device_exists_by_remote_id(remote_id: String) -> Result<bool> {
    let ctx = get_context();
    let exists = ctx.device_repo.exists_by_remote_id(&remote_id)?;
    Ok(exists)
}
