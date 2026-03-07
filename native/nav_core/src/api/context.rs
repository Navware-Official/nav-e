//! Application context and initialization.
//!
//! Holds the global AppContext (repos, services) and initialize_database / get_context.

use crate::domain::ports::{DeviceCommunicationPort, GeocodingService, NavigationRepository, RouteService};
use crate::infrastructure::{
    database::{
        Database, DeviceRepository, OfflineRegionsRepository, SavedPlacesRepository,
        SavedRoutesRepository, TripsRepository,
    },
    InMemoryNavigationRepository,
    NoOpDeviceComm,
    OsrmRouteService,
    PhotonGeocodingService,
};
use std::sync::{Arc, OnceLock};

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
}

impl AppContext {
    fn new_with_db_path(db_path: String) -> Self {
        let path = std::path::PathBuf::from(&db_path);
        let db = Database::new(path.clone()).expect("Failed to initialize database");

        let db_conn = db.get_connection();
        let storage_base = path
            .parent()
            .unwrap_or_else(|| std::path::Path::new("."))
            .join("offline_regions");
        let offline_regions_repo =
            OfflineRegionsRepository::new(Arc::clone(&db_conn), storage_base);

        Self {
            route_service: Arc::new(OsrmRouteService::new(
                "https://router.project-osrm.org".to_string(),
            )),
            geocoding_service: Arc::new(PhotonGeocodingService::new(
                "https://nominatim.openstreetmap.org".to_string(),
            )),
            navigation_repo: Arc::new(InMemoryNavigationRepository::new()),
            device_comm: Arc::new(NoOpDeviceComm),
            saved_places_repo: SavedPlacesRepository::new(Arc::clone(&db_conn)),
            saved_routes_repo: SavedRoutesRepository::new(Arc::clone(&db_conn)),
            trips_repo: TripsRepository::new(Arc::clone(&db_conn)),
            device_repo: DeviceRepository::new(db_conn),
            offline_regions_repo,
        }
    }
}

static APP_CONTEXT: OnceLock<AppContext> = OnceLock::new();

pub(crate) fn get_context() -> &'static AppContext {
    APP_CONTEXT
        .get()
        .expect("Database not initialized. Call initialize_database() first.")
}

/// Initialize the database with a platform-specific path
/// Must be called before any other API functions that access the database
pub fn initialize_database(db_path: String) -> anyhow::Result<()> {
    APP_CONTEXT.get_or_init(|| AppContext::new_with_db_path(db_path));
    Ok(())
}
