//! GraphHopper response → Nav-IR Route (stub for later).
//!
//! Placeholder for a future GraphHopper normalization adapter.

use crate::Route;

/// Normalize GraphHopper route JSON into a Nav-IR Route.
///
/// Not yet implemented. Use OSRM or custom_api for now.
pub fn normalize_graphhopper(_json: &str) -> Result<Route, String> {
    Err("GraphHopper adapter not yet implemented".to_string())
}
