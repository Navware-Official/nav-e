use serde::{Deserialize, Serialize};

/// Lightweight route DTO used across the FRB boundary.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct FrbRoute {
    pub id: String,
    /// Encoded polyline (polyline6 or polyline5 string). May be empty when
    /// the source provides geojson waypoints instead.
    pub polyline: String,
    pub distance_m: f64,
    pub duration_s: f64,
    /// Human-friendly route name
    pub name: String,
    /// A small preview of waypoints as [lat, lon] pairs for quick display or
    /// testing.
    pub waypoints: Vec<[f64; 2]>,
}
