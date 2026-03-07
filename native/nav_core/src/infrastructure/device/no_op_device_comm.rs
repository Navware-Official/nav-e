// No-op device communication stub used when no real device is connected.
use crate::domain::{entities::*, ports::*, value_objects::*};
use anyhow::Result;
use async_trait::async_trait;
use nav_ir::Route as NavIrRoute;

pub struct NoOpDeviceComm;

#[async_trait]
impl DeviceCommunicationPort for NoOpDeviceComm {
    async fn send_route_summary(&self, _device_id: String, _session: &NavigationSession) -> Result<()> {
        Ok(())
    }
    async fn send_route_blob(&self, _device_id: String, _route: &NavIrRoute) -> Result<()> {
        Ok(())
    }
    async fn send_position_update(&self, _device_id: String, _position: Position) -> Result<()> {
        Ok(())
    }
    async fn send_traffic_alert(&self, _device_id: String, _event: &TrafficEvent) -> Result<()> {
        Ok(())
    }
    async fn send_control_command(&self, _device_id: String, _command: ControlCommand) -> Result<()> {
        Ok(())
    }
}
