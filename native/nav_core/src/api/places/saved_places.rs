/// Saved places APIs
use anyhow::Result;

use crate::api::get_context;
use crate::api::helpers::*;
use crate::domain::ports::Repository;
use crate::infrastructure::database::SavedPlaceEntity;

/// Get all saved places as JSON array
pub fn get_all_saved_places() -> Result<String> {
    query_json(|| get_context().saved_places_repo.get_all())
}

/// Get a saved place by ID as JSON object
pub fn get_saved_place_by_id(id: i64) -> Result<String> {
    query_json(|| get_context().saved_places_repo.get_by_id(id))
}

/// Save a new place and return the assigned ID
pub fn save_place(
    name: String,
    address: Option<String>,
    lat: f64,
    lon: f64,
    source: Option<String>,
    type_id: Option<i64>,
    remote_id: Option<String>,
) -> Result<i64> {
    command_with_id(|| {
        let place = SavedPlaceEntity {
            id: None,
            type_id,
            source: source.unwrap_or_else(|| "manual".to_string()),
            remote_id,
            name,
            address,
            lat,
            lon,
            created_at: chrono::Utc::now().timestamp_millis(),
        };
        get_context().saved_places_repo.insert(place)
    })
}

/// Delete a saved place by ID
pub fn delete_saved_place(id: i64) -> Result<()> {
    command(|| get_context().saved_places_repo.delete(id))
}
