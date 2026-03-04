/// Device Communication APIs
///
/// Send navigation data to connected devices via Bluetooth using the device_comm crate.
/// Message preparation (route, map region, control, etc.) is implemented in device_comm;
/// this module keeps app-specific logic (e.g. resolve device by ID) and re-exports for FFI.
use anyhow::{bail, Context, Result};

use crate::api::get_device_by_id;

/// Send route data to a connected device via Bluetooth
///
/// Resolves the device by ID (database), then prepares the route message via device_comm.
/// Actual BLE transmission requires an active connection from the Flutter side.
pub fn send_route_to_device(device_id: i64, route_json: String) -> Result<()> {
    eprintln!("[RUST DEVICE_COMM] send_route_to_device called");
    eprintln!("[RUST DEVICE_COMM]   device_id: {}", device_id);
    eprintln!(
        "[RUST DEVICE_COMM]   route_json length: {} bytes",
        route_json.len()
    );

    let device_str =
        get_device_by_id(device_id).context("Failed to load device from database")?;
    let device: serde_json::Value =
        serde_json::from_str(&device_str).context("Failed to parse device JSON")?;

    let remote_id = device["remote_id"]
        .as_str()
        .ok_or_else(|| anyhow::anyhow!("Device missing remote_id (MAC address)"))?;
    eprintln!("[RUST DEVICE_COMM]   device remote_id: {}", remote_id);

    // Prepare message via device_comm (validates route JSON and builds proto)
    let _message_bytes = device_comm::prepare_route_message(route_json)
        .context("Failed to prepare route message")?;

    eprintln!("[RUST DEVICE_COMM] Route prepared successfully");
    eprintln!("[RUST DEVICE_COMM] NOTE: Actual Bluetooth transmission requires flutter_blue_plus integration");

    bail!(
        "Device communication prepared but not sent. \
        Bluetooth transmission requires active BLE connection from Flutter side. \
        Device: {} ({})",
        device_id,
        remote_id,
    )
}

// Re-export device_comm message APIs so FFI (nav_e_ffi) continues to use nav_core::api::*
pub use device_comm::{
    chunk_message_for_ble,
    create_control_message,
    prepare_map_region_metadata_message,
    prepare_map_style_message,
    prepare_route_message,
    prepare_tile_chunk_message,
    reassemble_frames,
};
