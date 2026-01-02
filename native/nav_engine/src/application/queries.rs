#![allow(dead_code)]
// Queries - Read operations (CQRS)
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Get active navigation session
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct GetActiveSessionQuery {}

/// Get navigation session by ID
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct GetSessionQuery {
    pub session_id: Uuid,
}

/// Get connected devices
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct GetConnectedDevicesQuery {}

/// Get device by ID
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct GetDeviceQuery {
    pub device_id: String,
}

/// Get traffic alerts for current route
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct GetTrafficAlertsQuery {
    pub session_id: Uuid,
}

/// Calculate route without starting navigation
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct CalculateRouteQuery {
    pub waypoints: Vec<crate::domain::value_objects::Position>,
}

/// Geocode an address
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct GeocodeQuery {
    pub address: String,
}

/// Reverse geocode a position
#[derive(Debug, Clone, Serialize, Deserialize)]

pub struct ReverseGeocodeQuery {
    pub position: crate::domain::value_objects::Position,
}
