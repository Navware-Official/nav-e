//! Application context and initialization.
//!
//! Holds the global AppContext (repos, services) and initialize_database / get_context.

use crate::domain::{
    events::NavigationEvent,
    ports::{DeviceCommunicationPort, GeocodingService, NavigationRepository, RouteService},
};
use crate::infrastructure::{
    database::{
        Database, DeviceRepository, OfflineRegionsRepository, SavedPlacesRepository,
        SavedRoutesRepository, TripsRepository,
    },
    NoOpDeviceComm, SqliteNavigationRepository,
};
use std::sync::{Arc, OnceLock};
use tokio::sync::broadcast;

pub(crate) struct AppContext {
    pub(crate) route_service: Arc<dyn RouteService>,
    pub(crate) geocoding_service: Arc<dyn GeocodingService>,
    pub(crate) navigation_repo: Arc<dyn NavigationRepository>,
    pub(crate) device_comm: Arc<dyn DeviceCommunicationPort>,
    pub(crate) saved_places_repo: SavedPlacesRepository,
    pub(crate) saved_routes_repo: SavedRoutesRepository,
    pub(crate) trips_repo: TripsRepository,
    pub(crate) device_repo: DeviceRepository,
    pub(crate) offline_regions_repo: OfflineRegionsRepository,
    pub(crate) event_bus: broadcast::Sender<NavigationEvent>,
}

impl AppContext {
    fn new(
        db_path: String,
        route_service: Arc<dyn RouteService>,
        geocoding_service: Arc<dyn GeocodingService>,
    ) -> Self {
        let path = std::path::PathBuf::from(&db_path);
        let db = Database::new(path.clone()).expect("Failed to initialize database");
        let db_conn = db.get_connection();

        let storage_base = path
            .parent()
            .unwrap_or_else(|| std::path::Path::new("."))
            .join("offline_regions");
        let offline_regions_repo =
            OfflineRegionsRepository::new(Arc::clone(&db_conn), storage_base);

        let (event_bus, _) = broadcast::channel(256);

        Self {
            route_service,
            geocoding_service,
            navigation_repo: Arc::new(SqliteNavigationRepository::new(Arc::clone(&db_conn))),
            device_comm: Arc::new(NoOpDeviceComm),
            saved_places_repo: SavedPlacesRepository::new(Arc::clone(&db_conn)),
            saved_routes_repo: SavedRoutesRepository::new(Arc::clone(&db_conn)),
            trips_repo: TripsRepository::new(Arc::clone(&db_conn)),
            device_repo: DeviceRepository::new(db_conn),
            offline_regions_repo,
            event_bus,
        }
    }
}

static APP_CONTEXT: OnceLock<AppContext> = OnceLock::new();

pub(crate) fn get_context() -> &'static AppContext {
    APP_CONTEXT
        .get()
        .expect("Database not initialized. Call initialize_database() first.")
}

/// Initialize the application with a platform-specific database path and injected services.
///
/// `route_service` and `geocoding_service` are provided by the caller (nav_e_ffi uses nav_route).
/// Must be called before any other API functions.
pub fn initialize_database(
    db_path: String,
    route_service: Arc<dyn RouteService>,
    geocoding_service: Arc<dyn GeocodingService>,
) -> anyhow::Result<()> {
    APP_CONTEXT.get_or_init(|| AppContext::new(db_path, route_service, geocoding_service));
    Ok(())
}

/// Subscribe to navigation events emitted by the application handlers.
///
/// Returns a `broadcast::Receiver<NavigationEvent>`. The receiver will receive all events
/// published after the subscribe call. Wrap in an FRB stream in nav_e_ffi for Flutter access.
pub fn subscribe_navigation_events() -> broadcast::Receiver<NavigationEvent> {
    get_context().event_bus.subscribe()
}
