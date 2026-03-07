// Queries - Read operations
use crate::domain::value_objects::Position;
use serde::{Deserialize, Serialize};

/// Get active navigation session
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GetActiveSessionQuery {}

/// Geocode an address
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeocodeQuery {
    pub address: String,
    pub limit: Option<u32>,
}

/// Reverse geocode a position
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReverseGeocodeQuery {
    pub position: Position,
}
