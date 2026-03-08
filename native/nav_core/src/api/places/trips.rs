/// Trips API - completed route history
use anyhow::Result;

use crate::api::helpers::*;
use crate::app::container::get_container;
use crate::places::commands::*;
use crate::places::queries::*;

/// Get all trips as JSON array (newest first)
pub fn get_all_trips() -> Result<String> {
    query_json(|| get_container().places.get_all_trips(GetAllTripsQuery))
}

/// Get a trip by ID as JSON object
pub fn get_trip_by_id(id: i64) -> Result<String> {
    query_json(|| get_container().places.get_trip_by_id(GetTripByIdQuery { id }))
}

/// Save a new trip and return the assigned ID
pub fn save_trip(
    distance_m: f64,
    duration_seconds: i64,
    started_at: i64,
    completed_at: i64,
    status: String,
    destination_label: Option<String>,
    route_id: Option<String>,
    polyline_encoded: Option<String>,
) -> Result<i64> {
    get_container().places.save_trip(SaveTripCommand {
        distance_m,
        duration_seconds,
        started_at,
        completed_at,
        status,
        destination_label,
        route_id,
        polyline_encoded,
    })
}

/// Delete a trip by ID
pub fn delete_trip(id: i64) -> Result<()> {
    get_container().places.delete_trip(DeleteTripCommand { id })
}
