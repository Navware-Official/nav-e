//! Protobuf device adapter — implements `DeviceCommunicationPort` using the `device_comm` crate.
//!
//! This adapter converts domain objects into serialized protobuf messages and publishes them on
//! a broadcast channel. Actual BLE writes are Flutter-side (`flutter_blue_plus`): Flutter
//! subscribes to the outgoing stream via `subscribe_device_messages()` and writes each payload
//! to the connected BLE peripheral.

use crate::navigation::domain::ports::{ControlCommand, DeviceCommunicationPort};
use crate::navigation::domain::session::{NavigationSession, TrafficEvent, TrafficSeverity};
use crate::shared::value_objects::Position;
use anyhow::{Context, Result};
use async_trait::async_trait;
use device_comm::{create_header, nav_ir_route_to_route_blob, proto};
use nav_ir::Route as NavIrRoute;
use prost::Message as ProstMessage;
use tokio::sync::broadcast;

/// An outgoing device message: the target device identifier plus serialized protobuf bytes.
///
/// Flutter receives these via the broadcast channel and writes each `bytes` payload to the
/// BLE peripheral identified by `device_id`.
#[derive(Clone, Debug)]
pub struct DeviceMessage {
    pub device_id: String,
    pub bytes: Vec<u8>,
}

/// Infrastructure adapter — serialises `DeviceCommunicationPort` calls to protobuf and
/// publishes them for Flutter's BLE layer.
///
/// Constructed once in [`AppContainer`] and shared as an `Arc`. Navigation handlers use it as
/// their `DeviceCommunicationPort`; the device API uses it to send explicit route bytes.
pub struct ProtobufDeviceAdapter {
    tx: broadcast::Sender<DeviceMessage>,
}

impl ProtobufDeviceAdapter {
    pub fn new() -> Self {
        let (tx, _) = broadcast::channel(64);
        Self { tx }
    }

    /// Subscribe to outgoing device messages. Each subscriber receives a full copy of every
    /// message published after the subscribe call.
    pub fn subscribe(&self) -> broadcast::Receiver<DeviceMessage> {
        self.tx.subscribe()
    }

    /// Publish raw serialized bytes to a device. Used by the device API to send pre-built
    /// messages (e.g. from `device_comm::prepare_route_message`) without going through the port.
    pub fn send_raw(&self, device_id: String, bytes: Vec<u8>) {
        let _ = self.tx.send(DeviceMessage { device_id, bytes });
    }

    fn serialize<T: ProstMessage>(msg: &T) -> Result<Vec<u8>> {
        let mut buf = Vec::new();
        msg.encode(&mut buf).context("Failed to encode protobuf")?;
        Ok(buf)
    }

    fn emit(&self, device_id: String, bytes: Vec<u8>) {
        let _ = self.tx.send(DeviceMessage { device_id, bytes });
    }
}

impl Default for ProtobufDeviceAdapter {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl DeviceCommunicationPort for ProtobufDeviceAdapter {
    async fn send_route_summary(
        &self,
        device_id: String,
        session: &NavigationSession,
    ) -> Result<()> {
        let route = &session.route;
        let distance_m = route
            .metadata
            .total_distance_m
            .map(|m| m as u32)
            .unwrap_or(0);
        let duration_s = route
            .metadata
            .estimated_duration_s
            .map(|s| s as u32)
            .unwrap_or(0);
        let eta_unix_ms = (chrono::Utc::now().timestamp() + duration_s as i64) as u64 * 1000;

        let summary = proto::RouteSummary {
            header: Some(create_header(1)),
            route_id: route.id.0.as_bytes().to_vec(),
            distance_m,
            eta_unix_ms,
            next_turn_text: String::from("Continue straight"),
            next_turn_bearing_deg: 0,
            remaining_distance_m: distance_m,
            estimated_duration_s: duration_s,
            bounding_box: None,
        };
        let bytes = Self::serialize(&summary)?;
        self.emit(device_id, bytes);
        Ok(())
    }

    async fn send_route_blob(&self, device_id: String, route: &NavIrRoute) -> Result<()> {
        let blob = nav_ir_route_to_route_blob(route, create_header(1))?;
        let bytes = Self::serialize(&blob)?;
        self.emit(device_id, bytes);
        Ok(())
    }

    async fn send_position_update(&self, device_id: String, position: Position) -> Result<()> {
        let update = proto::PositionUpdate {
            header: Some(create_header(1)),
            lat: position.latitude,
            lon: position.longitude,
            bearing_deg: 0,
            speed_m_s: 0.0,
            timestamp_ms: chrono::Utc::now().timestamp_millis() as u64,
            accuracy_m: 10.0,
            altitude_m: 0.0,
        };
        let bytes = Self::serialize(&update)?;
        self.emit(device_id, bytes);
        Ok(())
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
            header: Some(create_header(1)),
            route_id: vec![],
            alert_text: event.description.clone(),
            delay_seconds: event.delay_seconds as i32,
            distance_to_alert_m: event.distance_ahead_meters as f64,
            severity: severity as i32,
            alternative_route_id: String::new(),
        };
        let bytes = Self::serialize(&alert)?;
        self.emit(device_id, bytes);
        Ok(())
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
            header: Some(create_header(1)),
            r#type: cmd as i32,
            route_id: vec![],
            status_code: 0,
            message_text: String::new(),
            seq_no: 0,
        };
        let bytes = Self::serialize(&control)?;
        self.emit(device_id, bytes);
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn send_position_update_emits_bytes() {
        let adapter = ProtobufDeviceAdapter::new();
        let mut rx = adapter.subscribe();

        let pos = Position::new(52.37, 4.90).unwrap();
        adapter
            .send_position_update("dev-1".into(), pos)
            .await
            .unwrap();

        let msg = rx.recv().await.unwrap();
        assert_eq!(msg.device_id, "dev-1");
        assert!(!msg.bytes.is_empty());
    }

    #[tokio::test]
    async fn send_control_command_emits_bytes() {
        let adapter = ProtobufDeviceAdapter::new();
        let mut rx = adapter.subscribe();

        adapter
            .send_control_command("dev-2".into(), ControlCommand::Heartbeat)
            .await
            .unwrap();

        let msg = rx.recv().await.unwrap();
        assert_eq!(msg.device_id, "dev-2");
        assert!(!msg.bytes.is_empty());
    }

    #[tokio::test]
    async fn send_raw_emits_verbatim() {
        let adapter = ProtobufDeviceAdapter::new();
        let mut rx = adapter.subscribe();

        let payload = vec![1u8, 2, 3, 4];
        adapter.send_raw("dev-3".into(), payload.clone());

        let msg = rx.recv().await.unwrap();
        assert_eq!(msg.device_id, "dev-3");
        assert_eq!(msg.bytes, payload);
    }

    #[test]
    fn no_subscribers_does_not_panic() {
        let adapter = ProtobufDeviceAdapter::new();
        // No receiver held — emit should silently discard
        adapter.send_raw("dev-4".into(), vec![0xff]);
    }
}
