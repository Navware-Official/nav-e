/// Trips API - completed route history
use anyhow::Result;

use super::helpers::*;
use crate::domain::ports::Repository;
use crate::infrastructure::database::TripEntity;

/// Get all trips as JSON array (newest first)
pub fn get_all_trips() -> Result<String> {
    query_json(|| super::get_context().trips_repo.get_all())
}

/// Get a trip by ID as JSON object
pub fn get_trip_by_id(id: i64) -> Result<String> {
    query_json(|| super::get_context().trips_repo.get_by_id(id))
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
    command_with_id(|| {
        let ctx = super::get_context();
        let entity = TripEntity {
            id: None,
            distance_m,
            duration_seconds,
            started_at,
            completed_at,
            status,
            destination_label,
            route_id,
            polyline_encoded,
            created_at: completed_at,
        };
        ctx.trips_repo.insert(entity)
    })
}

/// Delete a trip by ID
pub fn delete_trip(id: i64) -> Result<()> {
    command(|| super::get_context().trips_repo.delete(id))
}
