#![allow(dead_code)]
use crc32fast::Hasher;
use prost::Message as ProstMessage;
use uuid::Uuid;

// Include generated protobuf code
pub mod proto {
    #![allow(clippy::all)]
    include!(concat!(env!("OUT_DIR"), "/navigation.rs"));
}

use proto::*;

const PROTOCOL_VERSION: u32 = 1;
const FRAME_MAGIC: u32 = 0x4E415645; // "NAVE"
const DEFAULT_MTU: usize = 247;
const FRAME_OVERHEAD: usize = 40;
/// Android BLE write-with-response limit; frames must not exceed this.
const BLE_MAX_WRITE_BYTES: usize = 512;
/// Conservative overhead for serialized Frame (tags, length prefixes, fixed fields).
const BLE_FRAME_SERIALIZED_OVERHEAD: usize = 50;

/// Result type for device communication operations
pub type Result<T> = std::result::Result<T, DeviceError>;

#[derive(Debug, thiserror::Error)]
pub enum DeviceError {
    #[error("Serialization error: {0}")]
    Serialization(#[from] prost::EncodeError),

    #[error("Deserialization error: {0}")]
    Deserialization(#[from] prost::DecodeError),

    #[error("CRC mismatch: expected {expected:08x}, got {actual:08x}")]
    CrcMismatch { expected: u32, actual: u32 },

    #[error("Invalid frame: {0}")]
    InvalidFrame(String),

    #[error("Missing sequence: {0}")]
    MissingSequence(u32),

    #[error("Timeout waiting for ACK")]
    Timeout,
}

/// Creates a header with current protocol version
pub(crate) fn create_header(message_version: u32) -> Header {
    Header {
        protocol_version: PROTOCOL_VERSION,
        message_version,
    }
}

/// Serialize a proto message to bytes
pub(crate) fn serialize_proto_message(msg: &proto::Message) -> Result<Vec<u8>> {
    let mut buf = Vec::new();
    ProstMessage::encode(msg, &mut buf)?;
    Ok(buf)
}

/// Deserialize a proto message from bytes
pub(crate) fn deserialize_proto_message(bytes: &[u8]) -> Result<proto::Message> {
    Ok(ProstMessage::decode(bytes)?)
}

/// Calculate CRC32 for a byte slice
pub(crate) fn calculate_crc32(data: &[u8]) -> u32 {
    let mut hasher = Hasher::new();
    hasher.update(data);
    hasher.finalize()
}

/// Split a message into frames for BLE transmission
pub fn chunk_message(
    msg: &proto::Message,
    route_id: &Uuid,
    msg_type: u32,
    mtu: usize,
) -> Result<Vec<Frame>> {
    let payload = serialize_proto_message(msg)?;
    // Keep serialized frame (header + payload) <= BLE_MAX_WRITE_BYTES (Android limit)
    let max_payload_per_frame =
        BLE_MAX_WRITE_BYTES.saturating_sub(BLE_FRAME_SERIALIZED_OVERHEAD);
    let chunk_size = (mtu - FRAME_OVERHEAD).min(max_payload_per_frame);
    let total_chunks = payload.len().div_ceil(chunk_size);

    let mut frames = Vec::new();

    for (seq, chunk) in payload.chunks(chunk_size).enumerate() {
        let crc = calculate_crc32(chunk);

        let frame = Frame {
            magic: FRAME_MAGIC,
            msg_type,
            protocol_version: PROTOCOL_VERSION,
            route_id: route_id.as_bytes().to_vec(),
            seq_no: seq as u32,
            total_seqs: total_chunks as u32,
            payload_len: chunk.len() as u32,
            flags: 0,
            payload: chunk.to_vec(),
            crc32: crc,
        };

        frames.push(frame);
    }

    Ok(frames)
}

/// Reassemble frames back into a message
pub struct FrameAssembler {
    frames: std::collections::HashMap<u32, Vec<u8>>,
    total_seqs: Option<u32>,
    route_id: Option<Uuid>,
}

impl FrameAssembler {
    pub fn new() -> Self {
        Self {
            frames: std::collections::HashMap::new(),
            total_seqs: None,
            route_id: None,
        }
    }

    /// Add a frame to the assembler
    pub fn add_frame(&mut self, frame: Frame) -> Result<()> {
        // Validate magic number
        if frame.magic != FRAME_MAGIC {
            return Err(DeviceError::InvalidFrame(format!(
                "Invalid magic: {:08x}",
                frame.magic
            )));
        }

        // Verify CRC
        let calculated_crc = calculate_crc32(&frame.payload);
        if calculated_crc != frame.crc32 {
            return Err(DeviceError::CrcMismatch {
                expected: frame.crc32,
                actual: calculated_crc,
            });
        }

        // Store route_id and total_seqs from first frame
        if self.route_id.is_none() {
            self.route_id = Some(
                Uuid::from_slice(&frame.route_id)
                    .map_err(|e| DeviceError::InvalidFrame(e.to_string()))?,
            );
            self.total_seqs = Some(frame.total_seqs);
        }

        // Add payload
        self.frames.insert(frame.seq_no, frame.payload);

        Ok(())
    }

    /// Check if all frames have been received
    pub fn is_complete(&self) -> bool {
        if let Some(total) = self.total_seqs {
            self.frames.len() == total as usize
        } else {
            false
        }
    }

    /// Get missing sequence numbers
    pub fn missing_sequences(&self) -> Vec<u32> {
        if let Some(total) = self.total_seqs {
            (0..total)
                .filter(|seq| !self.frames.contains_key(seq))
                .collect()
        } else {
            vec![]
        }
    }

    /// Assemble the complete message
    pub fn assemble(&self) -> Result<Vec<u8>> {
        if !self.is_complete() {
            return Err(DeviceError::InvalidFrame(
                "Not all frames received".to_string(),
            ));
        }

        let total = self.total_seqs.unwrap();
        let mut result = Vec::new();

        for seq in 0..total {
            if let Some(payload) = self.frames.get(&seq) {
                result.extend_from_slice(payload);
            } else {
                return Err(DeviceError::MissingSequence(seq));
            }
        }

        Ok(result)
    }

    pub fn reset(&mut self) {
        self.frames.clear();
        self.total_seqs = None;
        self.route_id = None;
    }
}

impl Default for FrameAssembler {
    fn default() -> Self {
        Self::new()
    }
}

/// Helper to create a RouteSummary from route data
#[allow(clippy::too_many_arguments)]
pub(crate) fn create_route_summary(
    route_id: Uuid,
    distance_m: u32,
    eta_unix_ms: u64,
    next_turn_text: String,
    next_turn_bearing: u32,
    remaining_distance: u32,
    estimated_duration: u32,
    bbox: (f64, f64, f64, f64),
) -> RouteSummary {
    RouteSummary {
        header: Some(create_header(1)),
        route_id: route_id.as_bytes().to_vec(),
        distance_m,
        eta_unix_ms,
        next_turn_text,
        next_turn_bearing_deg: next_turn_bearing,
        remaining_distance_m: remaining_distance,
        estimated_duration_s: estimated_duration,
        bounding_box: Some(BoundingBox {
            min_lat: bbox.0,
            min_lon: bbox.1,
            max_lat: bbox.2,
            max_lon: bbox.3,
        }),
    }
}

/// Helper to create a Control message
pub(crate) fn create_control(
    control_type: i32,
    route_id: Option<Uuid>,
    status_code: u32,
    message_text: String,
) -> Control {
    Control {
        header: Some(create_header(1)),
        r#type: control_type,
        route_id: route_id
            .map(|id| id.as_bytes().to_vec())
            .unwrap_or_default(),
        status_code,
        message_text,
        seq_no: 0,
    }
}

/// Helper to create a PositionUpdate
pub(crate) fn create_position_update(
    lat: f64,
    lon: f64,
    speed_m_s: f32,
    bearing_deg: u32,
    timestamp_ms: u64,
    accuracy_m: f32,
) -> PositionUpdate {
    PositionUpdate {
        header: Some(create_header(1)),
        lat,
        lon,
        speed_m_s,
        bearing_deg,
        timestamp_ms,
        accuracy_m,
        altitude_m: 0.0,
    }
}

/// Helper to create a TrafficAlert
pub(crate) fn create_traffic_alert(
    route_id: Uuid,
    alert_text: String,
    delay_seconds: i32,
    distance_to_alert_m: f64,
    severity: i32,
    alternative_route_id: Option<String>,
) -> TrafficAlert {
    TrafficAlert {
        header: Some(create_header(1)),
        route_id: route_id.as_bytes().to_vec(),
        alert_text,
        delay_seconds,
        distance_to_alert_m,
        severity,
        alternative_route_id: alternative_route_id.unwrap_or_default(),
    }
}

/// Helper to create a WaypointUpdate
pub(crate) fn create_waypoint_update(
    route_id: Uuid,
    remaining_waypoints: Vec<Waypoint>,
    current_index: i32,
    waypoint_eta_ms: Option<u64>,
) -> WaypointUpdate {
    WaypointUpdate {
        header: Some(create_header(1)),
        route_id: route_id.as_bytes().to_vec(),
        remaining_waypoints,
        current_waypoint_index: current_index,
        waypoint_eta_ms: waypoint_eta_ms.unwrap_or(0),
    }
}

/// Helper to create DeviceCapabilities
#[allow(clippy::too_many_arguments)]
pub(crate) fn create_device_capabilities(
    device_id: String,
    firmware_version: String,
    supports_vibration: bool,
    supports_voice: bool,
    screen_width: i32,
    screen_height: i32,
    battery_pct: i32,
    low_power_mode: bool,
) -> DeviceCapabilities {
    DeviceCapabilities {
        header: Some(create_header(1)),
        device_id,
        firmware_version,
        supports_vibration,
        supports_voice,
        screen_width_px: screen_width,
        screen_height_px: screen_height,
        battery_level_pct: battery_pct,
        low_power_mode,
    }
}

/// Helper to create BatteryStatus
pub(crate) fn create_battery_status(
    device_id: String,
    battery_pct: i32,
    is_charging: bool,
    estimated_minutes: Option<i32>,
) -> BatteryStatus {
    BatteryStatus {
        header: Some(create_header(1)),
        device_id,
        battery_pct,
        is_charging,
        estimated_minutes_remaining: estimated_minutes.unwrap_or(0),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_crc32_calculation() {
        let data = b"Hello, World!";
        let crc = calculate_crc32(data);
        assert_ne!(crc, 0);
    }

    #[test]
    fn test_frame_chunking_and_assembly() {
        let route_id = Uuid::new_v4();
        let summary = create_route_summary(
            route_id,
            5000,
            1234567890000,
            "Turn left".to_string(),
            90,
            4000,
            600,
            (52.0, 4.0, 52.5, 4.5),
        );

        let msg = proto::Message {
            payload: Some(proto::message::Payload::RouteSummary(summary)),
        };

        let frames = chunk_message(&msg, &route_id, 1, DEFAULT_MTU).unwrap();
        assert!(!frames.is_empty());

        let mut assembler = FrameAssembler::new();
        for frame in frames {
            assembler.add_frame(frame).unwrap();
        }

        assert!(assembler.is_complete());
        let reassembled = assembler.assemble().unwrap();
        let original = serialize_proto_message(&msg).unwrap();
        assert_eq!(reassembled, original);
    }

    #[test]
    fn test_control_message_creation() {
        let control = create_control(
            ControlType::Ack as i32,
            Some(Uuid::new_v4()),
            200,
            "OK".to_string(),
        );

        assert_eq!(control.status_code, 200);
        assert_eq!(control.message_text, "OK");
    }
}
