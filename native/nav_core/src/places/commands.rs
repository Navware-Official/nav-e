// Place, Trip, and SavedRoute write operations.
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SavePlaceCommand {
    pub name: String,
    pub address: Option<String>,
    pub lat: f64,
    pub lon: f64,
    pub source: Option<String>,
    pub type_id: Option<i64>,
    pub remote_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeletePlaceCommand {
    pub id: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SaveTripCommand {
    pub distance_m: f64,
    pub duration_seconds: i64,
    pub started_at: i64,
    pub completed_at: i64,
    pub status: String,
    pub destination_label: Option<String>,
    pub route_id: Option<String>,
    pub polyline_encoded: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeleteTripCommand {
    pub id: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SaveRouteFromJsonCommand {
    pub route_json: String,
    pub source: String,
}

#[derive(Debug, Clone)]
pub struct SaveRouteFromPlanCommand {
    pub name: String,
    pub waypoints: Vec<(f64, f64)>,
    pub polyline_encoded: Option<String>,
    pub distance_m: Option<f64>,
    pub duration_s: Option<u64>,
}

#[derive(Debug, Clone)]
pub struct ImportRouteFromGpxCommand {
    pub bytes: Vec<u8>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeleteSavedRouteCommand {
    pub id: i64,
}
