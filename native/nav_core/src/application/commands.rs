#![allow(dead_code)]
// Commands - Write operations (CQRS)
use crate::domain::value_objects::*;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Start a new navigation session
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct StartNavigationCommand {
    pub waypoints: Vec<Position>,
    pub current_position: Position,
    pub device_id: Option<String>,
}

/// Update current position during navigation
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct UpdatePositionCommand {
    pub session_id: Uuid,
    pub position: Position,
}

/// Pause active navigation
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct PauseNavigationCommand {
    pub session_id: Uuid,
}

/// Resume paused navigation
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct ResumeNavigationCommand {
    pub session_id: Uuid,
}

/// Stop/complete navigation
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct StopNavigationCommand {
    pub session_id: Uuid,
    pub completed: bool, // true = completed, false = cancelled
}

/// Register a new device
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct RegisterDeviceCommand {
    pub device_id: String,
    pub device_name: String,
    pub device_type: crate::domain::entities::DeviceType,
    pub capabilities: DeviceCapabilities,
}

/// Update device battery status
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct UpdateBatteryCommand {
    pub device_id: String,
    pub battery_info: BatteryInfo,
}

/// Send route to device
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct SendRouteToDeviceCommand {
    pub session_id: Uuid,
    pub device_id: String,
}

/// Report traffic event
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct ReportTrafficCommand {
    pub session_id: Uuid,
    pub position: Position,
    pub severity: crate::domain::entities::TrafficSeverity,
    pub delay_seconds: u32,
    pub description: String,
}
