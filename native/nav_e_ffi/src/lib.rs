mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
// FFI wrapper crate for nav_engine
//
// This crate provides a thin Flutter Rust Bridge wrapper around the nav_engine crate.
// All functions are simple pass-through wrappers that delegate to nav_engine's API.

use anyhow::Result;
use flutter_rust_bridge::frb;

// ============================================================================
// Initialization API
// ============================================================================

/// Initialize the database with the platform-specific path
/// Must be called before any database operations
#[frb]
pub fn initialize_database(db_path: String) -> Result<()> {
    nav_engine::api::initialize_database(db_path)
}

// ============================================================================
// Routes API
// ============================================================================

/// Calculate a route between waypoints
#[frb]
pub fn calculate_route(waypoints: Vec<(f64, f64)>) -> Result<String> {
    nav_engine::api::calculate_route(waypoints)
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
    nav_engine::api::start_navigation_session(waypoints, current_position)
}

/// Update current position during navigation
#[frb]
pub fn update_navigation_position(session_id: String, latitude: f64, longitude: f64) -> Result<()> {
    nav_engine::api::update_navigation_position(session_id, latitude, longitude)
}

/// Get the currently active navigation session
#[frb]
pub fn get_active_session() -> Result<Option<String>> {
    nav_engine::api::get_active_session()
}

/// Pause active navigation
#[frb]
pub fn pause_navigation(session_id: String) -> Result<()> {
    nav_engine::api::pause_navigation(session_id)
}

/// Resume paused navigation
#[frb]
pub fn resume_navigation(session_id: String) -> Result<()> {
    nav_engine::api::resume_navigation(session_id)
}

/// Stop and complete navigation session
#[frb]
pub fn stop_navigation(session_id: String) -> Result<()> {
    nav_engine::api::stop_navigation(session_id)
}

// ============================================================================
// Geocoding API
// ============================================================================

/// Search for locations by address/name
#[frb]
pub fn geocode_search(query: String, limit: Option<u32>) -> Result<String> {
    nav_engine::api::geocode_search(query, limit)
}

/// Reverse geocode coordinates to address
#[frb]
pub fn reverse_geocode(latitude: f64, longitude: f64) -> Result<String> {
    nav_engine::api::reverse_geocode(latitude, longitude)
}

// ============================================================================
// Saved Places API
// ============================================================================

/// Get all saved places as JSON array
#[frb(sync)]
pub fn get_all_saved_places() -> Result<String> {
    nav_engine::api::get_all_saved_places()
}

/// Get a saved place by ID as JSON object
#[frb(sync)]
pub fn get_saved_place_by_id(id: i64) -> Result<String> {
    nav_engine::api::get_saved_place_by_id(id)
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
    nav_engine::api::save_place(name, address, lat, lon, source, type_id, remote_id)
}

/// Delete a saved place by ID
#[frb(sync)]
pub fn delete_saved_place(id: i64) -> Result<()> {
    nav_engine::api::delete_saved_place(id)
}

// ============================================================================
// Device Communication API
// ============================================================================

/// Send route data to a connected device via Bluetooth
///
/// # Arguments
/// * `device_id` - The device ID (from saved devices)
/// * `route_json` - JSON string containing route waypoints and metadata
///
/// # Returns
/// Result indicating success or failure
///
/// # Note
/// Currently returns a stub implementation. Full device communication
/// will be implemented using device_comm crate and protobuf protocol.
#[frb]
pub fn send_route_to_device(device_id: i64, route_json: String) -> Result<()> {
    nav_engine::api::send_route_to_device(device_id, route_json)
}

// ============================================================================
// Devices API
// ============================================================================

/// Get all devices as JSON array
#[frb(sync)]
pub fn get_all_devices() -> Result<String> {
    nav_engine::api::get_all_devices()
}

/// Get a device by ID as JSON object
#[frb(sync)]
pub fn get_device_by_id(id: i64) -> Result<String> {
    nav_engine::api::get_device_by_id(id)
}

/// Get a device by remote ID as JSON object
#[frb(sync)]
pub fn get_device_by_remote_id(remote_id: String) -> Result<String> {
    nav_engine::api::get_device_by_remote_id(remote_id)
}

/// Save a new device from JSON and return the assigned ID
#[frb(sync)]
pub fn save_device(device_json: String) -> Result<i64> {
    nav_engine::api::save_device(device_json)
}

/// Update an existing device from JSON
#[frb(sync)]
pub fn update_device(id: i64, device_json: String) -> Result<()> {
    nav_engine::api::update_device(id, device_json)
}

/// Delete a device by ID
#[frb(sync)]
pub fn delete_device(id: i64) -> Result<()> {
    nav_engine::api::delete_device(id)
}

/// Check if a device exists by remote ID
#[frb(sync)]
pub fn device_exists_by_remote_id(remote_id: String) -> Result<bool> {
    nav_engine::api::device_exists_by_remote_id(remote_id)
}

// ============================================================================
// Device Communication API
// ============================================================================

/// Prepare a route message for sending to a device
/// Takes route JSON and returns serialized protobuf message bytes
#[frb(sync)]
pub fn prepare_route_message(route_json: String) -> Result<Vec<u8>> {
    nav_engine::api::prepare_route_message(route_json)
}

/// Chunk a protobuf message into BLE frames
/// Returns a vector of frame bytes ready for BLE transmission
#[frb(sync)]
pub fn chunk_message_for_ble(
    message_bytes: Vec<u8>,
    route_id: String,
    mtu: u32,
) -> Result<Vec<Vec<u8>>> {
    nav_engine::api::chunk_message_for_ble(message_bytes, route_id, mtu)
}

/// Reassemble BLE frames back into a complete message
/// Returns the reassembled message bytes
#[frb(sync)]
pub fn reassemble_frames(frame_bytes: Vec<Vec<u8>>) -> Result<Vec<u8>> {
    nav_engine::api::reassemble_frames(frame_bytes)
}

/// Create a control command message (ACK, NACK, START_NAV, etc.)
#[frb(sync)]
pub fn create_control_message(
    route_id: String,
    command_type: String,
    status_code: u32,
    message: String,
) -> Result<Vec<u8>> {
    nav_engine::api::create_control_message(route_id, command_type, status_code, message)
}

// ============================================================================
// Offline regions API
// ============================================================================

/// Get all offline regions as JSON array
#[frb(sync)]
pub fn get_all_offline_regions() -> Result<String> {
    nav_engine::api::get_all_offline_regions()
}

/// Get one offline region by id as JSON object (or null)
#[frb(sync)]
pub fn get_offline_region_by_id(id: String) -> Result<String> {
    nav_engine::api::get_offline_region_by_id(id)
}

/// Get list of tiles for a region as JSON array of {z, x, y}
#[frb(sync)]
pub fn get_offline_region_tile_list(region_id: String) -> Result<String> {
    nav_engine::api::get_offline_region_tile_list(region_id)
}

/// Read one tile file for a region. Returns raw .pbf bytes.
#[frb(sync)]
pub fn get_offline_region_tile_bytes(region_id: String, z: i32, x: i32, y: i32) -> Result<Vec<u8>> {
    nav_engine::api::get_offline_region_tile_bytes(region_id, z, x, y)
}

/// Build MapRegionMetadata protobuf message bytes for BLE transfer.
#[frb(sync)]
pub fn prepare_map_region_metadata_message(
    region_json: String,
    total_tiles: u32,
) -> Result<Vec<u8>> {
    nav_engine::api::prepare_map_region_metadata_message(region_json, total_tiles)
}

/// Build MapStyle protobuf message bytes for BLE transfer (sync map source to device).
#[frb(sync)]
pub fn prepare_map_style_message(map_source_id: String) -> Result<Vec<u8>> {
    nav_engine::api::prepare_map_style_message(map_source_id)
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
    nav_engine::api::prepare_tile_chunk_message(region_id, z, x, y, data)
}

/// Delete an offline region by id and remove its tile directory
#[frb(sync)]
pub fn delete_offline_region(id: String) -> Result<()> {
    nav_engine::api::delete_offline_region(id)
}

/// Get region for viewport bbox as JSON object (or null)
#[frb(sync)]
pub fn get_offline_region_for_viewport(
    north: f64,
    south: f64,
    east: f64,
    west: f64,
) -> Result<String> {
    nav_engine::api::get_offline_region_for_viewport(north, south, east, west)
}

/// Get storage root path for offline regions
#[frb(sync)]
pub fn get_offline_regions_storage_path() -> Result<String> {
    nav_engine::api::get_offline_regions_storage_path()
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
    nav_engine::api::download_offline_region(
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
