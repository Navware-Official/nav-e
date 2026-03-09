/// Device Communication APIs
///
/// Sends navigation data to connected devices via the `ProtobufDeviceAdapter`. The adapter
/// serialises domain objects to protobuf bytes and broadcasts them on a channel; Flutter
/// subscribes to that channel and performs the actual BLE write via `flutter_blue_plus`.
use anyhow::{Context, Result};

use crate::app::container::get_container;

/// Send route data to a connected device via Bluetooth.
///
/// Resolves the device by ID (database), prepares the protobuf route message via
/// `device_comm`, and emits the bytes on the device adapter's outgoing channel.
/// Flutter must be subscribed to `subscribe_device_messages()` to perform the BLE write.
pub fn send_route_to_device(device_id: i64, route_json: String) -> Result<()> {
    let container = get_container();

    let device_str = super::devices::get_device_by_id(device_id)
        .context("Failed to load device from database")?;
    let device: serde_json::Value =
        serde_json::from_str(&device_str).context("Failed to parse device JSON")?;

    let remote_id = device["remote_id"]
        .as_str()
        .ok_or_else(|| anyhow::anyhow!("Device missing remote_id (MAC address)"))?
        .to_string();

    // Serialize the route to protobuf bytes using device_comm.
    let message_bytes = device_comm::prepare_route_message(route_json)
        .context("Failed to prepare route message")?;

    // Emit on the BLE adapter channel — Flutter receives and writes over BLE.
    container.send_device_bytes(remote_id, message_bytes);

    Ok(())
}

// Re-export device_comm message preparation APIs so FFI uses nav_core::api::*
pub use device_comm::{
    chunk_message_for_ble, create_control_message, prepare_map_region_metadata_message,
    prepare_map_style_message, prepare_route_message, prepare_tile_chunk_message,
    reassemble_frames,
};

// Re-export subscribe_device_messages and DeviceMessage so the API surface stays at nav_core::api::*
pub use crate::app::container::subscribe_device_messages;
pub use crate::devices::infrastructure::ble_adapter::DeviceMessage;
