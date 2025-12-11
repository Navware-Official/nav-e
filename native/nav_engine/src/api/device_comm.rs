/// Device Communication APIs
/// 
/// This module provides APIs for sending navigation data to connected devices
/// via Bluetooth using the device_comm crate and protobuf protocol.

use anyhow::{Result, Context, bail};
use uuid::Uuid;
use crate::domain::ports::Repository;

/// Send route data to a connected device via Bluetooth
/// 
/// # Arguments
/// * `device_id` - The database ID of the device to send to
/// * `route_json` - JSON string containing route data with structure:
///   ```json
///   {
///     "waypoints": [[lat, lon], [lat, lon], ...],
///     "distance_m": 5000,
///     "duration_s": 600,
///     "polyline": "encoded_polyline_string"
///   }
///   ```
/// 
/// # Returns
/// Result indicating success or failure
/// 
/// # Current Implementation
/// Creates a protobuf RouteBlob message from the JSON data and prepares
/// it for transmission. Full Bluetooth transmission requires:
/// - Active Bluetooth connection to the device (via flutter_blue_plus on Flutter side)
/// - BLE characteristic for writing route data
/// - ACK/NACK handling for reliable delivery
/// 
/// # Future Steps
/// 1. Add async Bluetooth transport layer (requires tokio + platform-specific BLE APIs)
/// 2. Implement chunking for large routes (already available in device_comm crate)
/// 3. Add retry logic and timeout handling
/// 4. Store pending transmissions in database for reliability
pub fn send_route_to_device(device_id: i64, route_json: String) -> Result<()> {
    eprintln!("[RUST DEVICE_COMM] send_route_to_device called");
    eprintln!("[RUST DEVICE_COMM]   device_id: {}", device_id);
    eprintln!("[RUST DEVICE_COMM]   route_json length: {} bytes", route_json.len());
    
    // 1. Get device from database (using existing devices.rs API)
    let device_str = super::get_device_by_id(device_id)
        .context("Failed to load device from database")?;
    let device: serde_json::Value = serde_json::from_str(&device_str)
        .context("Failed to parse device JSON")?;
    
    let remote_id = device["remote_id"].as_str()
        .ok_or_else(|| anyhow::anyhow!("Device missing remote_id (MAC address)"))?;
    eprintln!("[RUST DEVICE_COMM]   device remote_id: {}", remote_id);
    
    // 2. Parse route JSON
    let route: serde_json::Value = serde_json::from_str(&route_json)
        .context("Failed to parse route JSON")?;
    
    // 3. Extract route data
    let waypoints = route["waypoints"].as_array()
        .ok_or_else(|| anyhow::anyhow!("Route missing waypoints array"))?;
    let distance_m = route["distance_m"].as_f64().unwrap_or(0.0) as u32;
    let duration_s = route["duration_s"].as_f64().unwrap_or(0.0) as u32;
    
    eprintln!("[RUST DEVICE_COMM]   waypoints: {}", waypoints.len());
    eprintln!("[RUST DEVICE_COMM]   distance: {} m, duration: {} s", distance_m, duration_s);
    
    // 4. Create protobuf message structure (not sent yet - needs Bluetooth connection)
    let route_id = Uuid::new_v4();
    eprintln!("[RUST DEVICE_COMM]   generated route_id: {}", route_id);
    
    // Convert waypoints to protobuf format
    let proto_waypoints: Vec<device_comm::proto::Waypoint> = waypoints
        .iter()
        .enumerate()
        .filter_map(|(i, wp)| {
            let arr = wp.as_array()?;
            let lat = arr.get(0)?.as_f64()?;
            let lon = arr.get(1)?.as_f64()?;
            Some(device_comm::proto::Waypoint {
                lat,
                lon,
                name: format!("Waypoint {}", i + 1),
                index: i as u32,
            })
        })
        .collect();
    
    eprintln!("[RUST DEVICE_COMM]   converted {} waypoints to protobuf", proto_waypoints.len());
    
    // TODO: Actual Bluetooth transmission
    // This requires:
    // - Flutter side to establish BLE connection using flutter_blue_plus
    // - Pass characteristic handle or use flutter_blue_plus to write chunks
    // - Or implement native Bluetooth in Rust (complex, platform-specific)
    //
    // For now, we've validated the data and created the protobuf structure
    // The actual transmission should be handled on the Flutter side using flutter_blue_plus
    // and calling a simpler FFI function like: send_route_chunk(device_id, chunk_bytes)
    
    eprintln!("[RUST DEVICE_COMM] Route prepared successfully");
    eprintln!("[RUST DEVICE_COMM] NOTE: Actual Bluetooth transmission requires flutter_blue_plus integration");
    
    bail!(
        "Device communication prepared but not sent. \
        Bluetooth transmission requires active BLE connection from Flutter side. \
        Device: {} ({}), Route ID: {}, Waypoints: {}, Distance: {}m",
        device_id, remote_id, route_id, proto_waypoints.len(), distance_m
    )
}
