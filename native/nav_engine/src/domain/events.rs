#![allow(dead_code)]
// Domain Events - Events that represent something that happened in the domain
use crate::domain::{entities::*, value_objects::*};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Base trait for domain events (internal use only, not exposed to FFI)
pub trait DomainEvent: Send + Sync {
    fn event_id(&self) -> Uuid;
    fn occurred_at(&self) -> DateTime<Utc>;
    fn aggregate_id(&self) -> Uuid;
}

/// Navigation session started
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct NavigationStartedEvent {
    pub event_id: Uuid,

    pub session_id: Uuid,

    pub route_id: Uuid,

    pub occurred_at: DateTime<Utc>,
}

impl NavigationStartedEvent {
    pub fn new(session_id: Uuid, route_id: Uuid) -> Self {
        Self {
            event_id: Uuid::new_v4(),
            session_id,
            route_id,
            occurred_at: Utc::now(),
        }
    }
}

/// Position was updated during navigation
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct PositionUpdatedEvent {
    pub event_id: Uuid,

    pub session_id: Uuid,
    pub position: Position,

    pub occurred_at: DateTime<Utc>,
}

impl PositionUpdatedEvent {
    pub fn new(session_id: Uuid, position: Position) -> Self {
        Self {
            event_id: Uuid::new_v4(),
            session_id,
            position,
            occurred_at: Utc::now(),
        }
    }
}

/// Waypoint reached
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct WaypointReachedEvent {
    pub event_id: Uuid,

    pub session_id: Uuid,
    pub waypoint_index: usize,
    pub position: Position,

    pub occurred_at: DateTime<Utc>,
}

impl WaypointReachedEvent {
    pub fn new(session_id: Uuid, waypoint_index: usize, position: Position) -> Self {
        Self {
            event_id: Uuid::new_v4(),
            session_id,
            waypoint_index,
            position,
            occurred_at: Utc::now(),
        }
    }
}

/// Navigation completed
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct NavigationCompletedEvent {
    pub event_id: Uuid,

    pub session_id: Uuid,
    pub total_distance_meters: f64,
    pub total_duration_seconds: u32,

    pub occurred_at: DateTime<Utc>,
}

impl NavigationCompletedEvent {
    pub fn new(session_id: Uuid, total_distance_meters: f64, total_duration_seconds: u32) -> Self {
        Self {
            event_id: Uuid::new_v4(),
            session_id,
            total_distance_meters,
            total_duration_seconds,
            occurred_at: Utc::now(),
        }
    }
}

/// Device connected
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct DeviceConnectedEvent {
    pub event_id: Uuid,
    pub device_id: String,
    pub device_type: DeviceType,

    pub occurred_at: DateTime<Utc>,
}

impl DeviceConnectedEvent {
    pub fn new(device_id: String, device_type: DeviceType) -> Self {
        Self {
            event_id: Uuid::new_v4(),
            device_id: device_id.clone(),
            device_type,
            occurred_at: Utc::now(),
        }
    }
}

/// Traffic alert detected
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct TrafficAlertDetectedEvent {
    pub event_id: Uuid,

    pub session_id: Uuid,
    pub traffic_event: TrafficEvent,

    pub occurred_at: DateTime<Utc>,
}

impl TrafficAlertDetectedEvent {
    pub fn new(session_id: Uuid, traffic_event: TrafficEvent) -> Self {
        Self {
            event_id: Uuid::new_v4(),
            session_id,
            traffic_event,
            occurred_at: Utc::now(),
        }
    }
}
