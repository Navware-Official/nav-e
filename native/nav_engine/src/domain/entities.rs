#![allow(dead_code)]
// Domain Entities - Core business objects with identity
use crate::domain::value_objects::*;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Represents an active navigation session

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NavigationSession {
    pub id: Uuid,
    pub route: Route,
    pub current_position: Position,
    pub status: NavigationStatus,
    pub started_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl NavigationSession {
    pub fn new(route: Route, initial_position: Position) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            route,
            current_position: initial_position,
            status: NavigationStatus::Active,
            started_at: now,
            updated_at: now,
        }
    }

    pub fn update_position(&mut self, position: Position) {
        self.current_position = position;
        self.updated_at = Utc::now();
    }

    pub fn complete(&mut self) {
        self.status = NavigationStatus::Completed;
        self.updated_at = Utc::now();
    }

    pub fn pause(&mut self) {
        self.status = NavigationStatus::Paused;
        self.updated_at = Utc::now();
    }

    pub fn resume(&mut self) {
        self.status = NavigationStatus::Active;
        self.updated_at = Utc::now();
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum NavigationStatus {
    Active,
    Paused,
    Completed,
    Cancelled,
}

/// Represents a route with waypoints

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Route {
    pub id: Uuid,
    pub waypoints: Vec<Waypoint>,
    pub polyline: Vec<Position>,
    pub distance_meters: f64,
    pub duration_seconds: u32,
    pub created_at: DateTime<Utc>,
}

impl Route {
    pub fn new(
        waypoints: Vec<Waypoint>,
        polyline: Vec<Position>,
        distance_meters: f64,
        duration_seconds: u32,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            waypoints,
            polyline,
            distance_meters,
            duration_seconds,
            created_at: Utc::now(),
        }
    }

    pub fn total_waypoints(&self) -> usize {
        self.waypoints.len()
    }
}

/// Device connected to the navigation system

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Device {
    pub id: String,
    pub name: String,
    pub device_type: DeviceType,
    pub capabilities: DeviceCapabilities,
    pub battery_status: Option<BatteryInfo>,
    pub connected_at: DateTime<Utc>,
    pub last_seen: DateTime<Utc>,
}

impl Device {
    pub fn new(
        id: String,
        name: String,
        device_type: DeviceType,
        capabilities: DeviceCapabilities,
    ) -> Self {
        let now = Utc::now();
        Self {
            id,
            name,
            device_type,
            capabilities,
            battery_status: None,
            connected_at: now,
            last_seen: now,
        }
    }

    pub fn update_battery(&mut self, battery: BatteryInfo) {
        self.battery_status = Some(battery);
        self.last_seen = Utc::now();
    }

    pub fn update_last_seen(&mut self) {
        self.last_seen = Utc::now();
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DeviceType {
    WearOsWatch,
    CustomBleDevice,
    Smartphone,
}

/// Traffic alert affecting navigation

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrafficEvent {
    pub id: Uuid,
    pub position: Position,
    pub severity: TrafficSeverity,
    pub delay_seconds: u32,
    pub distance_ahead_meters: u32,
    pub description: String,
    pub reported_at: DateTime<Utc>,
}

impl TrafficEvent {
    pub fn new(
        position: Position,
        severity: TrafficSeverity,
        delay_seconds: u32,
        distance_ahead_meters: u32,
        description: String,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            position,
            severity,
            delay_seconds,
            distance_ahead_meters,
            description,
            reported_at: Utc::now(),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TrafficSeverity {
    Unknown,
    Low,
    Medium,
    High,
    Critical,
}
