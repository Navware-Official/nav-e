#![allow(dead_code)]
// Protobuf Adapter - Device communication using Protocol Buffers
use crate::domain::{entities::*, ports::*, value_objects::*};
use anyhow::{Context, Result};
use async_trait::async_trait;
use device_comm::proto;
use prost::Message as ProstMessage;
use std::sync::Arc;
use tokio::sync::Mutex;

/// Adapter that translates domain models to protobuf messages
pub struct ProtobufDeviceCommunicator {
    // In real implementation, this would be BLE or network transport
    transport: Arc<Mutex<dyn DeviceTransport>>,
}

impl ProtobufDeviceCommunicator {
    // Not exposed to FFI - Mutex type conflict between std and tokio
    pub(crate) fn new(transport: Arc<Mutex<dyn DeviceTransport>>) -> Self {
        Self { transport }
    }

    fn create_header() -> proto::Header {
        proto::Header {
            protocol_version: 1,
            message_version: 1,
        }
    }

    fn serialize_protobuf<T: ProstMessage>(msg: &T) -> Result<Vec<u8>> {
        let mut buf = Vec::new();
        msg.encode(&mut buf)
            .context("Failed to encode protobuf message")?;
        Ok(buf)
    }
}

#[async_trait]
impl DeviceCommunicationPort for ProtobufDeviceCommunicator {
    async fn send_route_summary(
        &self,
        device_id: String,
        session: &NavigationSession,
    ) -> Result<()> {
        let summary = proto::RouteSummary {
            header: Some(Self::create_header()),
            route_id: session.route.id.as_bytes().to_vec(),
            distance_m: session.route.distance_meters as u32,
            eta_unix_ms: (chrono::Utc::now().timestamp() + session.route.duration_seconds as i64)
                as u64
                * 1000,
            next_turn_text: String::from("Continue straight"),
            next_turn_bearing_deg: 0,
            remaining_distance_m: session.route.distance_meters as u32,
            estimated_duration_s: session.route.duration_seconds,
            bounding_box: None, // TODO: Calculate from route
        };

        let data = Self::serialize_protobuf(&summary)?;
        self.transport.lock().await.send(&device_id, data).await
    }

    async fn send_route_blob(&self, device_id: String, route: &Route) -> Result<()> {
        // Serialize route polyline as JSON
        let polyline_json = serde_json::to_string(&route.polyline)?;

        // Create waypoints
        let waypoints: Vec<proto::Waypoint> = route
            .waypoints
            .iter()
            .enumerate()
            .map(|(idx, wp)| proto::Waypoint {
                lat: wp.position.latitude,
                lon: wp.position.longitude,
                name: wp.name.clone().unwrap_or_default(),
                index: idx as u32,
            })
            .collect();

        // Create checksum (simple SHA256)
        use sha2::{Digest, Sha256};
        let mut hasher = Sha256::new();
        hasher.update(polyline_json.as_bytes());
        let checksum = hasher.finalize().to_vec();

        let blob = proto::RouteBlob {
            header: Some(Self::create_header()),
            route_id: route.id.as_bytes().to_vec(),
            waypoints,
            legs: vec![], // TODO: Convert route legs
            polyline_data: Some(proto::route_blob::PolylineData::EncodedPolyline(
                polyline_json,
            )),
            metadata: None,
            compressed: false,
            checksum,
            signature: None,
        };

        let data = Self::serialize_protobuf(&blob)?;

        // Chunk large messages for BLE transmission
        let chunks = chunk_data(&data, 240); // MTU - overhead

        for chunk in chunks.iter() {
            self.transport
                .lock()
                .await
                .send(&device_id, chunk.clone())
                .await?;
        }

        Ok(())
    }

    async fn send_position_update(&self, device_id: String, position: Position) -> Result<()> {
        let update = proto::PositionUpdate {
            header: Some(Self::create_header()),
            lat: position.latitude,
            lon: position.longitude,
            bearing_deg: 0, // TODO: Calculate from movement
            speed_m_s: 0.0, // TODO: Calculate from position history
            timestamp_ms: chrono::Utc::now().timestamp_millis() as u64,
            accuracy_m: 10.0,
            altitude_m: 0.0,
        };

        let data = Self::serialize_protobuf(&update)?;
        self.transport.lock().await.send(&device_id, data).await
    }

    async fn send_traffic_alert(&self, device_id: String, event: &TrafficEvent) -> Result<()> {
        let severity = match event.severity {
            TrafficSeverity::Unknown => proto::AlertSeverity::SeverityUnknown,
            TrafficSeverity::Low => proto::AlertSeverity::Low,
            TrafficSeverity::Medium => proto::AlertSeverity::Medium,
            TrafficSeverity::High => proto::AlertSeverity::High,
            TrafficSeverity::Critical => proto::AlertSeverity::Critical,
        };

        let alert = proto::TrafficAlert {
            header: Some(Self::create_header()),
            route_id: vec![], // TODO: Get from session
            alert_text: event.description.clone(),
            delay_seconds: event.delay_seconds as i32,
            distance_to_alert_m: event.distance_ahead_meters as f64,
            severity: severity as i32,
            alternative_route_id: String::new(),
        };

        let data = Self::serialize_protobuf(&alert)?;
        self.transport.lock().await.send(&device_id, data).await
    }

    async fn send_control_command(&self, device_id: String, command: ControlCommand) -> Result<()> {
        let cmd = match command {
            ControlCommand::StartNavigation => proto::ControlType::StartNav,
            ControlCommand::PauseNavigation => proto::ControlType::PauseNav,
            ControlCommand::ResumeNavigation => proto::ControlType::ResumeNav,
            ControlCommand::StopNavigation => proto::ControlType::StopNav,
            ControlCommand::Acknowledge => proto::ControlType::Ack,
            ControlCommand::NegativeAcknowledge => proto::ControlType::Nack,
            ControlCommand::Heartbeat => proto::ControlType::Heartbeat,
        };

        let control = proto::Control {
            header: Some(Self::create_header()),
            r#type: cmd as i32,
            route_id: vec![],
            status_code: 0,
            message_text: String::new(),
            seq_no: 0,
        };

        let data = Self::serialize_protobuf(&control)?;
        self.transport.lock().await.send(&device_id, data).await
    }
}

/// Transport abstraction for different communication channels
#[async_trait]
pub trait DeviceTransport: Send + Sync {
    async fn send(&mut self, device_id: &str, data: Vec<u8>) -> Result<()>;
    async fn receive(&mut self) -> Result<(String, Vec<u8>)>; // Returns (device_id, data)
}

/// Helper function to chunk data for BLE transmission
fn chunk_data(data: &[u8], chunk_size: usize) -> Vec<Vec<u8>> {
    data.chunks(chunk_size)
        .map(|chunk| chunk.to_vec())
        .collect()
}
