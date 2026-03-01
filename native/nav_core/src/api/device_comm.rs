/// Device Communication APIs
///
/// This module provides APIs for sending navigation data to connected devices
/// via Bluetooth using the device_comm crate and protobuf protocol.
/// Route data is built as Nav-IR then converted to RouteBlob (single pipeline).
use anyhow::{bail, Context, Result};
use uuid::Uuid;

use crate::infrastructure::nav_ir_to_proto;
use chrono::Utc;
use device_comm::proto;
use nav_ir::{
    BoundingBox, EncodedPolyline, GeometryConfidence, GeometrySource, Route as NavIrRoute,
    RouteGeometry, RouteMetadata, RoutePolicies, RouteSegment, SegmentConstraints, SegmentId,
    SegmentIntent, Waypoint as NavIrWaypoint, WaypointId, WaypointKind,
};
use prost::Message as ProstMessage;

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
    eprintln!(
        "[RUST DEVICE_COMM]   route_json length: {} bytes",
        route_json.len()
    );

    // 1. Get device from database (using existing devices.rs API)
    let device_str =
        super::get_device_by_id(device_id).context("Failed to load device from database")?;
    let device: serde_json::Value =
        serde_json::from_str(&device_str).context("Failed to parse device JSON")?;

    let remote_id = device["remote_id"]
        .as_str()
        .ok_or_else(|| anyhow::anyhow!("Device missing remote_id (MAC address)"))?;
    eprintln!("[RUST DEVICE_COMM]   device remote_id: {}", remote_id);

    // 2. Parse route JSON
    let route: serde_json::Value =
        serde_json::from_str(&route_json).context("Failed to parse route JSON")?;

    // 3. Extract route data
    let waypoints = route["waypoints"]
        .as_array()
        .ok_or_else(|| anyhow::anyhow!("Route missing waypoints array"))?;
    let distance_m = route["distance_m"].as_f64().unwrap_or(0.0) as u32;
    let duration_s = route["duration_s"].as_f64().unwrap_or(0.0) as u32;

    eprintln!("[RUST DEVICE_COMM]   waypoints: {}", waypoints.len());
    eprintln!(
        "[RUST DEVICE_COMM]   distance: {} m, duration: {} s",
        distance_m, duration_s
    );

    // 4. Create protobuf message structure (not sent yet - needs Bluetooth connection)
    let route_id = Uuid::new_v4();
    eprintln!("[RUST DEVICE_COMM]   generated route_id: {}", route_id);

    // Convert waypoints to protobuf format
    let proto_waypoints: Vec<device_comm::proto::Waypoint> = waypoints
        .iter()
        .enumerate()
        .filter_map(|(i, wp)| {
            let arr = wp.as_array()?;
            let lat = arr.first()?.as_f64()?;
            let lon = arr.get(1)?.as_f64()?;
            Some(device_comm::proto::Waypoint {
                lat,
                lon,
                name: format!("Waypoint {}", i + 1),
                index: i as u32,
            })
        })
        .collect();

    eprintln!(
        "[RUST DEVICE_COMM]   converted {} waypoints to protobuf",
        proto_waypoints.len()
    );

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
        device_id,
        remote_id,
        route_id,
        proto_waypoints.len(),
        distance_m
    )
}

/// Prepare a route message for sending to a device.
/// Parses route JSON into Nav-IR Route, then to RouteBlob (single pipeline).
pub fn prepare_route_message(route_json: String) -> Result<Vec<u8>> {
    let route_value: serde_json::Value =
        serde_json::from_str(&route_json).context("Failed to parse route JSON")?;

    let waypoints_arr = route_value["waypoints"]
        .as_array()
        .ok_or_else(|| anyhow::anyhow!("Route missing waypoints array"))?;
    let nav_ir_waypoints: Vec<NavIrWaypoint> = waypoints_arr
        .iter()
        .enumerate()
        .filter_map(|(i, wp)| {
            let arr = wp.as_array()?;
            let lat = arr.first()?.as_f64()?;
            let lon = arr.get(1)?.as_f64()?;
            let kind = if i == 0 {
                WaypointKind::Start
            } else if i == waypoints_arr.len() - 1 {
                WaypointKind::Stop
            } else {
                WaypointKind::Via
            };
            Some(NavIrWaypoint {
                id: WaypointId::new(),
                coordinate: nav_ir::Coordinate::new(lat, lon),
                kind,
                radius_m: None,
                name: None,
                description: None,
                role: None,
                category: None,
                geometry_ref: None,
            })
        })
        .collect();

    let (encoded_polyline, min_lat, max_lat, min_lon, max_lon) =
        if let Some(arr) = route_value["polyline"].as_array() {
            let coords: Vec<_> = arr
                .iter()
                .filter_map(|v| {
                    let pair = v.as_array()?;
                    let lat = pair.first()?.as_f64()?;
                    let lon = pair.get(1)?.as_f64()?;
                    Some((lat, lon))
                })
                .collect();
            let (min_lat, max_lat, min_lon, max_lon) = coords.iter().fold(
                (90.0_f64, -90.0_f64, 180.0_f64, -180.0_f64),
                |(min_lat, max_lat, min_lon, max_lon), (lat, lon)| {
                    (
                        min_lat.min(*lat),
                        max_lat.max(*lat),
                        min_lon.min(*lon),
                        max_lon.max(*lon),
                    )
                },
            );
            let coords_geo: Vec<geo_types::Coord<f64>> = coords
                .iter()
                .map(|(lat, lon)| geo_types::Coord { x: *lon, y: *lat })
                .collect();
            let encoded = polyline::encode_coordinates(coords_geo, 5).unwrap_or_default();
            (encoded, min_lat, max_lat, min_lon, max_lon)
        } else {
            let encoded = route_value["polyline"].as_str().unwrap_or("");
            let decoded = polyline::decode_polyline(encoded, 5)
                .map_err(|e| anyhow::anyhow!("Polyline decode: {}", e))?;
            let (min_lat, max_lat, min_lon, max_lon) = decoded.coords().fold(
                (90.0_f64, -90.0_f64, 180.0_f64, -180.0_f64),
                |(min_lat, max_lat, min_lon, max_lon), c| {
                    (
                        min_lat.min(c.y),
                        max_lat.max(c.y),
                        min_lon.min(c.x),
                        max_lon.max(c.x),
                    )
                },
            );
            (encoded.to_string(), min_lat, max_lat, min_lon, max_lon)
        };

    let distance_m = route_value["distance_m"].as_f64().unwrap_or(0.0);
    let duration_s = route_value["duration_s"].as_f64().unwrap_or(0.0) as u64;
    let now = Utc::now();

    let nav_ir_route = NavIrRoute {
        schema_version: NavIrRoute::CURRENT_SCHEMA_VERSION,
        id: nav_ir::RouteId::new(),
        metadata: RouteMetadata {
            name: String::new(),
            description: None,
            created_at: now,
            updated_at: now,
            total_distance_m: Some(distance_m),
            estimated_duration_s: Some(duration_s),
            tags: vec![],
            source: None,
        },
        segments: vec![RouteSegment {
            id: SegmentId::new(),
            intent: SegmentIntent::Recalculatable,
            geometry: RouteGeometry {
                polyline: EncodedPolyline(encoded_polyline),
                source: GeometrySource::SnappedToGraph,
                confidence: GeometryConfidence::High,
                bounding_box: BoundingBox {
                    min_lat,
                    min_lon,
                    max_lat,
                    max_lon,
                },
            },
            waypoints: nav_ir_waypoints,
            legs: vec![],
            instructions: vec![],
            constraints: SegmentConstraints::default(),
        }],
        policies: RoutePolicies::default(),
    };

    let header = proto::Header {
        protocol_version: 1,
        message_version: 1,
    };
    let route_blob = nav_ir_to_proto::nav_ir_route_to_route_blob(&nav_ir_route, header)?;

    let message = proto::Message {
        payload: Some(proto::message::Payload::RouteBlob(route_blob)),
    };

    let mut buf = Vec::new();
    message
        .encode(&mut buf)
        .context("Failed to encode protobuf message")?;
    Ok(buf)
}

/// Chunk a protobuf message into BLE frames
/// Returns a vector of frame bytes ready for BLE transmission
pub fn chunk_message_for_ble(
    message_bytes: Vec<u8>,
    route_id: String,
    mtu: u32,
) -> Result<Vec<Vec<u8>>> {
    use device_comm::proto::Message as ProtoMessage;
    use prost::Message as ProstMessage;

    // Deserialize message
    let message =
        ProtoMessage::decode(&message_bytes[..]).context("Failed to decode protobuf message")?;

    // Parse route UUID
    let route_uuid = Uuid::parse_str(&route_id).context("Invalid route UUID")?;

    // Chunk message using device_comm
    let frames = device_comm::chunk_message(&message, &route_uuid, 1, mtu as usize)
        .context("Failed to chunk message")?;

    // Serialize each frame to bytes
    let mut frame_bytes = Vec::new();
    for frame in frames {
        let mut buf = Vec::new();
        frame.encode(&mut buf).context("Failed to encode frame")?;
        frame_bytes.push(buf);
    }

    Ok(frame_bytes)
}

/// Build a MapRegionMetadata protobuf message and return serialized bytes.
/// region_json: JSON object with id, name, north, south, east, west, min_zoom, max_zoom.
/// total_tiles: number of tiles the device should expect (TileChunk count).
pub fn prepare_map_region_metadata_message(
    region_json: String,
    total_tiles: u32,
) -> Result<Vec<u8>> {
    use device_comm::proto;
    use prost::Message as ProstMessage;

    let region: serde_json::Value =
        serde_json::from_str(&region_json).context("Parse region JSON")?;
    let region_id = region["id"].as_str().unwrap_or("").to_string();
    let name = region["name"].as_str().unwrap_or("").to_string();
    let north = region["north"].as_f64().unwrap_or(0.0);
    let south = region["south"].as_f64().unwrap_or(0.0);
    let east = region["east"].as_f64().unwrap_or(0.0);
    let west = region["west"].as_f64().unwrap_or(0.0);
    let min_zoom = region["min_zoom"].as_i64().unwrap_or(0) as u32;
    let max_zoom = region["max_zoom"].as_i64().unwrap_or(0) as u32;

    let metadata = proto::MapRegionMetadata {
        region_id,
        name,
        north,
        south,
        east,
        west,
        min_zoom,
        max_zoom,
        total_tiles,
    };

    let message = proto::Message {
        payload: Some(proto::message::Payload::MapRegionMetadata(metadata)),
    };

    let mut buf = Vec::new();
    message
        .encode(&mut buf)
        .context("Encode MapRegionMetadata message")?;
    Ok(buf)
}

/// Build a MapStyle protobuf message for syncing map source to device.
pub fn prepare_map_style_message(map_source_id: String) -> Result<Vec<u8>> {
    use device_comm::proto;
    use prost::Message as ProstMessage;

    let map_style = proto::MapStyle { map_source_id };

    let message = proto::Message {
        payload: Some(proto::message::Payload::MapStyle(map_style)),
    };

    let mut buf = Vec::new();
    message
        .encode(&mut buf)
        .context("Encode MapStyle message")?;
    Ok(buf)
}

/// Build a TileChunk protobuf message and return serialized bytes.
pub fn prepare_tile_chunk_message(
    region_id: String,
    z: i32,
    x: i32,
    y: i32,
    data: Vec<u8>,
) -> Result<Vec<u8>> {
    use device_comm::proto;
    use prost::Message as ProstMessage;

    let chunk = proto::TileChunk {
        region_id,
        z,
        x,
        y,
        data,
    };

    let message = proto::Message {
        payload: Some(proto::message::Payload::TileChunk(chunk)),
    };

    let mut buf = Vec::new();
    message
        .encode(&mut buf)
        .context("Encode TileChunk message")?;
    Ok(buf)
}

/// Reassemble BLE frames back into a complete message
/// Returns the reassembled message bytes
pub fn reassemble_frames(frame_bytes: Vec<Vec<u8>>) -> Result<Vec<u8>> {
    use device_comm::proto::Frame;
    use device_comm::FrameAssembler;
    use prost::Message as ProstMessage;

    let mut reassembler = FrameAssembler::new();

    // Deserialize and add each frame
    for bytes in frame_bytes {
        let frame = Frame::decode(&bytes[..]).context("Failed to decode frame")?;
        reassembler
            .add_frame(frame)
            .context("Failed to add frame to reassembler")?;
    }

    // Check if complete and assemble
    if !reassembler.is_complete() {
        bail!(
            "Not all frames received. Missing: {:?}",
            reassembler.missing_sequences()
        );
    }

    let message_bytes = reassembler
        .assemble()
        .context("Failed to assemble frames")?;

    // Deserialize to Message to validate
    use device_comm::proto::Message as ProtoMessage2;
    let message = ProtoMessage2::decode(&message_bytes[..])
        .context("Failed to decode reassembled message")?;

    // Serialize to bytes
    let mut buf = Vec::new();
    message
        .encode(&mut buf)
        .context("Failed to encode reassembled message")?;

    Ok(buf)
}

/// Create a control command message (ACK, NACK, START_NAV, etc.)
pub fn create_control_message(
    route_id: String,
    command_type: String,
    status_code: u32,
    message: String,
) -> Result<Vec<u8>> {
    use device_comm::proto;
    use prost::Message as ProstMessage;

    // Parse command type
    let control_type = match command_type.to_uppercase().as_str() {
        "ACK" => proto::ControlType::Ack,
        "NACK" => proto::ControlType::Nack,
        "START_NAV" => proto::ControlType::StartNav,
        "STOP_NAV" => proto::ControlType::StopNav,
        "PAUSE_NAV" => proto::ControlType::PauseNav,
        "RESUME_NAV" => proto::ControlType::ResumeNav,
        "HEARTBEAT" => proto::ControlType::Heartbeat,
        _ => bail!("Invalid control type: {}", command_type),
    };

    // Create header
    let header = proto::Header {
        protocol_version: 1,
        message_version: 1,
    };

    // Parse route_id as UUID so we send 16 bytes (proto expects bytes route_id = 16 bytes UUID)
    let route_uuid =
        Uuid::parse_str(&route_id).context("Invalid route UUID for control message")?;
    let control = proto::Control {
        header: Some(header),
        r#type: control_type as i32,
        route_id: route_uuid.as_bytes().to_vec(),
        status_code,
        message_text: message,
        seq_no: 0,
    };

    // Wrap in Message
    let msg = proto::Message {
        payload: Some(proto::message::Payload::Control(control)),
    };

    // Serialize to bytes
    let mut buf = Vec::new();
    msg.encode(&mut buf)
        .context("Failed to encode control message")?;

    Ok(buf)
}
