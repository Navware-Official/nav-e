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
use std::sync::Mutex;
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
    /// Last known position + timestamp for bearing and speed calculation.
    #[allow(dead_code)]
    last_pos: Mutex<Option<(nav_ir::Coordinate, chrono::DateTime<chrono::Utc>)>>,
}

impl ProtobufDeviceAdapter {
    pub fn new() -> Self {
        let (tx, _) = broadcast::channel(64);
        Self {
            tx,
            last_pos: Mutex::new(None),
        }
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

        let bounding_box = compute_route_bounding_box(route).map(|bb| proto::BoundingBox {
            min_lat: bb.min_lat,
            max_lat: bb.max_lat,
            min_lon: bb.min_lon,
            max_lon: bb.max_lon,
        });

        let summary = proto::RouteSummary {
            header: Some(create_header(1)),
            route_id: route.id.0.as_bytes().to_vec(),
            distance_m,
            eta_unix_ms,
            next_turn_text: String::from("Continue straight"),
            next_turn_bearing_deg: 0,
            remaining_distance_m: distance_m,
            estimated_duration_s: duration_s,
            bounding_box,
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
        let now = chrono::Utc::now();
        let current_coord = nav_ir::Coordinate::new(position.latitude, position.longitude);

        let (bearing_deg, speed_m_s) = {
            let mut last = self.last_pos.lock().unwrap();
            let result = if let Some((prev_coord, prev_time)) = last.as_ref() {
                let bearing = compute_bearing(*prev_coord, current_coord) as u32;
                let elapsed_s = (now - *prev_time).num_milliseconds() as f64 / 1000.0;
                let dist_m =
                    nav_engine::derive_instructions::haversine_distance(*prev_coord, current_coord);
                let speed = if elapsed_s > 0.0 {
                    dist_m / elapsed_s
                } else {
                    0.0
                };
                (bearing, speed as f32)
            } else {
                (0u32, 0.0f32)
            };
            *last = Some((current_coord, now));
            result
        };

        let update = proto::PositionUpdate {
            header: Some(create_header(1)),
            lat: position.latitude,
            lon: position.longitude,
            bearing_deg,
            speed_m_s,
            timestamp_ms: now.timestamp_millis() as u64,
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

/// Merge all segment bounding boxes to produce the route's overall bounding box.
#[allow(dead_code)]
fn compute_route_bounding_box(route: &NavIrRoute) -> Option<nav_ir::BoundingBox> {
    let mut iter = route
        .segments
        .iter()
        .map(|s| s.geometry.bounding_box.clone());
    let first = iter.next()?;
    Some(iter.fold(first, |acc, bb| nav_ir::BoundingBox {
        min_lat: acc.min_lat.min(bb.min_lat),
        max_lat: acc.max_lat.max(bb.max_lat),
        min_lon: acc.min_lon.min(bb.min_lon),
        max_lon: acc.max_lon.max(bb.max_lon),
    }))
}

/// Forward bearing in degrees (0–360) from `from` to `to`.
#[allow(dead_code)]
fn compute_bearing(from: nav_ir::Coordinate, to: nav_ir::Coordinate) -> f64 {
    let lat1 = from.latitude.to_radians();
    let lat2 = to.latitude.to_radians();
    let dlon = (to.longitude - from.longitude).to_radians();
    let y = dlon.sin() * lat2.cos();
    let x = lat1.cos() * lat2.sin() - lat1.sin() * lat2.cos() * dlon.cos();
    (y.atan2(x).to_degrees() + 360.0) % 360.0
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
