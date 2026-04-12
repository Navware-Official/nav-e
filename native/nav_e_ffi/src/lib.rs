mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
// FFI wrapper crate for nav_core
//
// This crate provides a thin Flutter Rust Bridge wrapper around the nav_core crate.
// All functions are simple pass-through wrappers that delegate to nav_core's API.

use anyhow::Result;
use flutter_rust_bridge::frb;
use std::collections::HashMap;
use std::sync::{Arc, OnceLock};

/// Global handle to the MultiRouteService so `set_routing_engine` can switch
/// engines without going through AppContainer.
static MULTI_ROUTER: OnceLock<Arc<nav_route::MultiRouteService>> = OnceLock::new();

// ============================================================================
// Initialization API
// ============================================================================

/// Initialize the database and routing engines.
///
/// Always registers OSRM (public) and Valhalla (public openstreetmap.de instance).
/// Pass `google_routes_api_key` to also enable Google Routes — obtain a key via
/// `--dart-define=GOOGLE_ROUTES_KEY=...` at build time.
///
/// Must be called before any other API functions.
#[frb]
pub fn initialize_database(db_path: String, google_routes_api_key: Option<String>) -> Result<()> {
    let mut engines: HashMap<String, Arc<dyn nav_core::RouteService>> = HashMap::new();

    engines.insert(
        "osrm".to_string(),
        Arc::new(nav_route::OsrmRouteService::new(
            "https://router.project-osrm.org".to_string(),
        )),
    );

    engines.insert(
        "valhalla".to_string(),
        Arc::new(nav_route::ValhallaRouteService::new(
            "https://valhalla1.openstreetmap.de".to_string(),
            None,
        )),
    );

    if let Some(key) = google_routes_api_key {
        if !key.is_empty() {
            engines.insert(
                "googleRoutes".to_string(),
                Arc::new(nav_route::GoogleRoutesService::new(key)),
            );
        }
    }

    let multi = Arc::new(nav_route::MultiRouteService::new(
        "osrm".to_string(),
        engines,
    ));

    let _ = MULTI_ROUTER.set(Arc::clone(&multi));

    let nominatim = Arc::new(nav_route::NominatimGeocodingService::new(
        "https://nominatim.openstreetmap.org".to_string(),
    ));
    let navdsp_geo = Arc::new(nav_route::NavDspGeocodingService::new());
    let geocoding_service = Arc::new(nav_route::FallbackGeocodingService::new(
        navdsp_geo, nominatim,
    ));

    nav_core::api::initialize_database(db_path, multi, geocoding_service)
}

/// Configure the nav-dsp gateway base URL, optional JWT token, and per-service toggles.
/// Call this after initialize_database, and again whenever the token changes.
/// Setting geocoding_enabled to false falls back to Nominatim transparently.
#[frb]
pub fn set_navdsp_config(
    base_url: String,
    token: Option<String>,
    geocoding_enabled: bool,
) -> Result<()> {
    nav_route::navdsp::config::set_config(base_url, token, geocoding_enabled);
    Ok(())
}

/// Switch the active routing engine. Valid names: `"osrm"`, `"valhalla"`, `"googleRoutes"`.
/// Google Routes is only available if an API key was provided to `initialize_database`.
#[frb]
pub fn set_routing_engine(engine: String) -> Result<()> {
    MULTI_ROUTER
        .get()
        .ok_or_else(|| anyhow::anyhow!("Router not initialized — call initialize_database first"))?
        .set_engine(&engine)
}

// ============================================================================
// Routes API
// ============================================================================

/// Calculate a route between waypoints
#[frb]
pub fn calculate_route(waypoints: Vec<(f64, f64)>) -> Result<String> {
    nav_core::api::calculate_route(waypoints)
}

// ============================================================================
// Navigation API
// ============================================================================

/// Start a new navigation session
#[frb]
pub fn start_navigation_session(
    waypoints: Vec<(f64, f64)>,
    current_position: (f64, f64),
) -> Result<String> {
    nav_core::api::start_navigation_session(waypoints, current_position)
}

/// Update current position during navigation. Returns `NavigationStateDto` as JSON.
#[frb]
pub fn update_navigation_position(
    session_id: String,
    latitude: f64,
    longitude: f64,
) -> Result<String> {
    nav_core::api::update_navigation_position(session_id, latitude, longitude)
}

/// Get the latest navigation state for an active session without moving.
/// Returns `NavigationStateDto` JSON or null if session not found.
#[frb]
pub fn get_navigation_state(session_id: String) -> Result<Option<String>> {
    nav_core::api::get_navigation_state(session_id)
}

/// Get the currently active navigation session
#[frb]
pub fn get_active_session() -> Result<Option<String>> {
    nav_core::api::get_active_session()
}

/// Pause active navigation
#[frb]
pub fn pause_navigation(session_id: String) -> Result<()> {
    nav_core::api::pause_navigation(session_id)
}

/// Resume paused navigation
#[frb]
pub fn resume_navigation(session_id: String) -> Result<()> {
    nav_core::api::resume_navigation(session_id)
}

/// Stop and complete navigation session
#[frb]
pub fn stop_navigation(session_id: String) -> Result<()> {
    nav_core::api::stop_navigation(session_id)
}

/// Get aggregated stats (distance, duration, count) from all non-cancelled sessions
#[frb]
pub fn get_session_stats() -> Result<String> {
    nav_core::api::get_session_stats()
}

/// Get all route steps (turn-by-turn instructions) for a session as JSON array
#[frb]
pub fn get_route_steps(session_id: String) -> Result<String> {
    nav_core::api::get_route_steps(session_id)
}

// ============================================================================
// Geocoding API
// ============================================================================

/// Search for locations by address/name
#[frb]
pub fn geocode_search(query: String, limit: Option<u32>) -> Result<String> {
    nav_core::api::geocode_search(query, limit)
}

/// Reverse geocode coordinates to address
#[frb]
pub fn reverse_geocode(latitude: f64, longitude: f64) -> Result<String> {
    nav_core::api::reverse_geocode(latitude, longitude)
}

// ============================================================================
// Saved Places API
// ============================================================================

/// Get all saved places as JSON array
#[frb(sync)]
pub fn get_all_saved_places() -> Result<String> {
    nav_core::api::get_all_saved_places()
}

/// Get a saved place by ID as JSON object
#[frb(sync)]
pub fn get_saved_place_by_id(id: i64) -> Result<String> {
    nav_core::api::get_saved_place_by_id(id)
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
    nav_core::api::save_place(name, address, lat, lon, source, type_id, remote_id)
}

/// Delete a saved place by ID
#[frb(sync)]
pub fn delete_saved_place(id: i64) -> Result<()> {
    nav_core::api::delete_saved_place(id)
}

// ============================================================================
// Trips API (completed route history)
// ============================================================================

/// Get all trips as JSON array
#[frb(sync)]
pub fn get_all_trips() -> Result<String> {
    nav_core::api::get_all_trips()
}

/// Get a trip by ID as JSON object
#[frb(sync)]
pub fn get_trip_by_id(id: i64) -> Result<String> {
    nav_core::api::get_trip_by_id(id)
}

/// Save a new trip and return the assigned ID
#[frb(sync)]
pub fn save_trip(
    distance_m: f64,
    duration_seconds: i64,
    started_at: i64,
    completed_at: i64,
    status: String,
    destination_label: Option<String>,
    route_id: Option<String>,
    polyline_encoded: Option<String>,
) -> Result<i64> {
    nav_core::api::save_trip(
        distance_m,
        duration_seconds,
        started_at,
        completed_at,
        status,
        destination_label,
        route_id,
        polyline_encoded,
    )
}

/// Delete a trip by ID
#[frb(sync)]
pub fn delete_trip(id: i64) -> Result<()> {
    nav_core::api::delete_trip(id)
}

// ============================================================================
// Saved Routes API
// ============================================================================

/// Parse GPX bytes into Nav-IR route JSON without saving. Use for preview-before-save flow.
#[frb(sync)]
pub fn parse_route_from_gpx(bytes: Vec<u8>) -> Result<String> {
    nav_core::api::parse_route_from_gpx(&bytes)
}

/// Save a pre-parsed route (Nav-IR JSON) to the database. Returns the saved entity as JSON.
#[frb(sync)]
pub fn save_route_from_json(route_json: String, source: String) -> Result<String> {
    nav_core::api::save_route_from_json(&route_json, source)
}

/// Import a route from GPX bytes, persist it, and return the saved route as JSON.
#[frb(sync)]
pub fn import_route_from_gpx(bytes: Vec<u8>) -> Result<String> {
    nav_core::api::import_route_from_gpx(&bytes)
}

/// Save the current plan-route (waypoints + polyline) as a saved route. Returns the new row id.
#[frb(sync)]
pub fn save_route_from_plan(
    name: String,
    waypoints: Vec<(f64, f64)>,
    polyline_encoded: Option<String>,
    distance_m: Option<f64>,
    duration_s: Option<u64>,
) -> Result<i64> {
    nav_core::api::save_route_from_plan(name, waypoints, polyline_encoded, distance_m, duration_s)
}

/// Get all saved routes as JSON array (newest first).
#[frb(sync)]
pub fn get_all_saved_routes() -> Result<String> {
    nav_core::api::get_all_saved_routes()
}

/// Get a saved route by ID as JSON object (or null if not found).
#[frb(sync)]
pub fn get_saved_route_by_id(id: i64) -> Result<String> {
    nav_core::api::get_saved_route_by_id(id)
}

/// Delete a saved route by ID.
#[frb(sync)]
pub fn delete_saved_route(id: i64) -> Result<()> {
    nav_core::api::delete_saved_route(id)
}

// ============================================================================
// Device Communication API
// ============================================================================

/// Send route data to a connected device via Bluetooth.
///
/// Serialises the route to protobuf via `nav_protocol` and emits the bytes on the
/// device message channel. Flutter must be subscribed to `subscribe_device_messages()`
/// to receive and write them over BLE.
#[frb]
pub fn send_route_to_device(device_id: i64, route_json: String) -> Result<()> {
    nav_core::api::send_route_to_device(device_id, route_json)
}

// NOTE: subscribe_device_messages() is available in nav_core::api but requires FRB stream
// wiring to expose to Flutter. See nav_core::api::subscribe_device_messages and
// DeviceMessage for the shape. Wire as a StreamSink<DeviceMessage> when BLE streaming is needed.

// ============================================================================
// Devices API
// ============================================================================

/// Get all devices as JSON array
#[frb(sync)]
pub fn get_all_devices() -> Result<String> {
    nav_core::api::get_all_devices()
}

/// Get a device by ID as JSON object
#[frb(sync)]
pub fn get_device_by_id(id: i64) -> Result<String> {
    nav_core::api::get_device_by_id(id)
}

/// Get a device by remote ID as JSON object
#[frb(sync)]
pub fn get_device_by_remote_id(remote_id: String) -> Result<String> {
    nav_core::api::get_device_by_remote_id(remote_id)
}

/// Save a new device from JSON and return the assigned ID
#[frb(sync)]
pub fn save_device(device_json: String) -> Result<i64> {
    nav_core::api::save_device(device_json)
}

/// Update an existing device from JSON
#[frb(sync)]
pub fn update_device(id: i64, device_json: String) -> Result<()> {
    nav_core::api::update_device(id, device_json)
}

/// Delete a device by ID
#[frb(sync)]
pub fn delete_device(id: i64) -> Result<()> {
    nav_core::api::delete_device(id)
}

/// Check if a device exists by remote ID
#[frb(sync)]
pub fn device_exists_by_remote_id(remote_id: String) -> Result<bool> {
    nav_core::api::device_exists_by_remote_id(remote_id)
}

// ============================================================================
// Device Communication API
// ============================================================================

/// Prepare a route message for sending to a device
/// Takes route JSON and returns serialized protobuf message bytes
#[frb(sync)]
pub fn prepare_route_message(route_json: String) -> Result<Vec<u8>> {
    nav_core::api::prepare_route_message(route_json)
}

/// Chunk a protobuf message into BLE frames
/// Returns a vector of frame bytes ready for BLE transmission
#[frb(sync)]
pub fn chunk_message_for_ble(
    message_bytes: Vec<u8>,
    route_id: String,
    mtu: u32,
) -> Result<Vec<Vec<u8>>> {
    nav_core::api::chunk_message_for_ble(message_bytes, route_id, mtu)
}

/// Reassemble BLE frames back into a complete message
/// Returns the reassembled message bytes
#[frb(sync)]
pub fn reassemble_frames(frame_bytes: Vec<Vec<u8>>) -> Result<Vec<u8>> {
    nav_core::api::reassemble_frames(frame_bytes)
}

/// Create a control command message (ACK, NACK, START_NAV, etc.)
#[frb(sync)]
pub fn create_control_message(
    route_id: String,
    command_type: String,
    status_code: u32,
    message: String,
) -> Result<Vec<u8>> {
    nav_core::api::create_control_message(route_id, command_type, status_code, message)
}

// ============================================================================
// Offline regions API
// ============================================================================

/// Get all offline regions as JSON array
#[frb(sync)]
pub fn get_all_offline_regions() -> Result<String> {
    nav_core::api::get_all_offline_regions()
}

/// Get one offline region by id as JSON object (or null)
#[frb(sync)]
pub fn get_offline_region_by_id(id: String) -> Result<String> {
    nav_core::api::get_offline_region_by_id(id)
}

/// Get list of tiles for a region as JSON array of {z, x, y}
#[frb(sync)]
pub fn get_offline_region_tile_list(region_id: String) -> Result<String> {
    nav_core::api::get_offline_region_tile_list(region_id)
}

/// Read one tile file for a region. Returns raw .pbf bytes.
#[frb(sync)]
pub fn get_offline_region_tile_bytes(region_id: String, z: i32, x: i32, y: i32) -> Result<Vec<u8>> {
    nav_core::api::get_offline_region_tile_bytes(region_id, z, x, y)
}

/// Build MapRegionMetadata protobuf message bytes for BLE transfer.
#[frb(sync)]
pub fn prepare_map_region_metadata_message(
    region_json: String,
    total_tiles: u32,
) -> Result<Vec<u8>> {
    nav_core::api::prepare_map_region_metadata_message(region_json, total_tiles)
}

/// Build MapStyle protobuf message bytes for BLE transfer (sync map source to device).
#[frb(sync)]
pub fn prepare_map_style_message(map_source_id: String) -> Result<Vec<u8>> {
    nav_core::api::prepare_map_style_message(map_source_id)
}

/// Build TileChunk protobuf message bytes for BLE transfer.
#[frb(sync)]
pub fn prepare_tile_chunk_message(
    region_id: String,
    z: i32,
    x: i32,
    y: i32,
    data: Vec<u8>,
) -> Result<Vec<u8>> {
    nav_core::api::prepare_tile_chunk_message(region_id, z, x, y, data)
}

/// Delete an offline region by id and remove its tile directory
#[frb(sync)]
pub fn delete_offline_region(id: String) -> Result<()> {
    nav_core::api::delete_offline_region(id)
}

/// Get region for viewport bbox as JSON object (or null)
#[frb(sync)]
pub fn get_offline_region_for_viewport(
    north: f64,
    south: f64,
    east: f64,
    west: f64,
) -> Result<String> {
    nav_core::api::get_offline_region_for_viewport(north, south, east, west)
}

/// Get storage root path for offline regions
#[frb(sync)]
pub fn get_offline_regions_storage_path() -> Result<String> {
    nav_core::api::get_offline_regions_storage_path()
}

/// Download a region: fetch tiles, write to directory, insert into DB. Returns region JSON.
#[frb(sync)]
pub fn download_offline_region(
    name: String,
    north: f64,
    south: f64,
    east: f64,
    west: f64,
    min_zoom: i32,
    max_zoom: i32,
    tile_url_template: Option<String>,
) -> Result<String> {
    nav_core::api::download_offline_region(
        name,
        north,
        south,
        east,
        west,
        min_zoom,
        max_zoom,
        tile_url_template,
    )
}
