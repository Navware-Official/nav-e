//! Application container — composition root for all bounded contexts.
//!
//! Replaces the old `AppContext` god-object with a structured container where each
//! bounded context owns its pre-constructed handlers. The `OnceLock` guarantees a
//! single initialization for the lifetime of the mobile app process.

use crate::devices::handlers::DevicesHandlers;
use crate::devices::infrastructure::{DeviceMessage, ProtobufDeviceAdapter};
use crate::infrastructure::database::{
    Database, DeviceRepository, OfflineRegionsRepository, SavedPlacesRepository,
    SavedRoutesRepository, TripsRepository,
};
use crate::navigation::application::handlers::{GeocodingHandlers, NavigationHandlers};
use crate::navigation::domain::{
    events::NavigationEvent,
    ports::{GeocodingService, NavigationRepository, RouteService},
};
use crate::navigation::infrastructure::SqliteNavigationRepository;
use crate::offline::handlers::OfflineHandlers;
use crate::places::handlers::PlacesHandlers;
use std::sync::{Arc, OnceLock};
use tokio::sync::broadcast;

/// Application container — holds all bounded-context handler groups.
///
/// Constructed once at startup via [`initialize_database`] and stored in
/// `APP_CONTAINER`. API layer functions call into this struct; no raw repos
/// or services are accessed outside of this module.
pub(crate) struct AppContainer {
    pub(crate) navigation: NavigationHandlers,
    pub(crate) geocoding: GeocodingHandlers,
    pub(crate) places: PlacesHandlers,
    pub(crate) devices: DevicesHandlers,
    pub(crate) offline: OfflineHandlers,
    /// The real BLE adapter — stored separately so both navigation and the device API
    /// can send messages, and Flutter can subscribe to the outgoing stream.
    device_adapter: Arc<ProtobufDeviceAdapter>,
}

impl AppContainer {
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

        let (event_bus, _) = broadcast::channel::<NavigationEvent>(256);

        let navigation_repo: Arc<dyn NavigationRepository> =
            Arc::new(SqliteNavigationRepository::new(Arc::clone(&db_conn)));

        // Real device adapter — serialises domain messages to protobuf bytes.
        // Navigation uses it via DeviceCommunicationPort; Flutter subscribes to its channel.
        let device_adapter = Arc::new(ProtobufDeviceAdapter::new());

        Self {
            navigation: NavigationHandlers::new(
                route_service,
                navigation_repo,
                Arc::clone(&device_adapter) as _,
                event_bus,
            ),
            geocoding: GeocodingHandlers::new(geocoding_service),
            places: PlacesHandlers::new(
                SavedPlacesRepository::new(Arc::clone(&db_conn)),
                TripsRepository::new(Arc::clone(&db_conn)),
                SavedRoutesRepository::new(Arc::clone(&db_conn)),
            ),
            devices: DevicesHandlers::new(DeviceRepository::new(Arc::clone(&db_conn))),
            offline: OfflineHandlers::new(OfflineRegionsRepository::new(
                Arc::clone(&db_conn),
                storage_base,
            )),
            device_adapter,
        }
    }

    /// Subscribe to outgoing device messages serialised by `ProtobufDeviceAdapter`.
    ///
    /// Flutter calls this once at startup and streams each `DeviceMessage` to the BLE
    /// peripheral identified by `device_id`. The channel is broadcast — multiple
    /// subscribers each receive a full copy.
    pub fn subscribe_device_messages(&self) -> broadcast::Receiver<DeviceMessage> {
        self.device_adapter.subscribe()
    }

    /// Send pre-built protobuf bytes to a device. Used by `send_route_to_device` to
    /// emit messages that were prepared via the `device_comm` helper functions.
    pub(crate) fn send_device_bytes(&self, device_id: String, bytes: Vec<u8>) {
        self.device_adapter.send_raw(device_id, bytes);
    }
}

static APP_CONTAINER: OnceLock<AppContainer> = OnceLock::new();

pub(crate) fn get_container() -> &'static AppContainer {
    APP_CONTAINER
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
    APP_CONTAINER.get_or_init(|| AppContainer::new(db_path, route_service, geocoding_service));
    Ok(())
}

/// Subscribe to navigation events emitted by the navigation handlers.
pub fn subscribe_navigation_events() -> broadcast::Receiver<NavigationEvent> {
    get_container().navigation.subscribe()
}

/// Subscribe to outgoing device messages (protobuf bytes destined for BLE peripherals).
///
/// Flutter calls this once and streams messages to the connected BLE device.
pub fn subscribe_device_messages() -> broadcast::Receiver<DeviceMessage> {
    get_container().subscribe_device_messages()
}
