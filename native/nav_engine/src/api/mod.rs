/// API module - Feature-based organization
///
/// This module provides the API surface organized by feature/domain.
/// Clean, type-safe, and follows domain-driven design principles.
pub mod dto;
pub mod helpers;

// Feature modules - public for FRB-generated code but not re-exported from crate
pub(crate) mod device_comm;
pub(crate) mod devices;
pub(crate) mod geocoding;
pub(crate) mod navigation;
pub(crate) mod offline_regions;
pub(crate) mod routes;
pub(crate) mod saved_places;

// Re-export all public APIs
pub use device_comm::*;
pub use devices::*;
pub use geocoding::*;
pub use navigation::*;
pub use offline_regions::*;
pub use routes::*;
pub use saved_places::*;

use crate::infrastructure::{
    database::{Database, DeviceRepository, OfflineRegionsRepository, SavedPlacesRepository},
    geocoding_adapter::PhotonGeocodingService,
    in_memory_repo::InMemoryNavigationRepository,
    osrm_adapter::OsrmRouteService,
};
use std::sync::{Arc, OnceLock};

// ============================================================================
// Global Application Context - Internal Only, FRB-compatible
// ============================================================================

use crate::domain::ports::{GeocodingService, NavigationRepository, RouteService};

// Keep pub(crate) +  so FRB can generate code but it's not exported from the crate

pub(crate) struct AppContext {
    route_service: Arc<dyn RouteService>,
    geocoding_service: Arc<dyn GeocodingService>,
    navigation_repo: Arc<dyn NavigationRepository>,
    saved_places_repo: SavedPlacesRepository,
    device_repo: DeviceRepository,
    offline_regions_repo: OfflineRegionsRepository,
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
            saved_places_repo: SavedPlacesRepository::new(Arc::clone(&db_conn)),
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

// Re-export helpers for use in API functions
pub use helpers::*;
