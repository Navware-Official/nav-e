/// Saved places APIs
use anyhow::Result;

use super::helpers::*;
use crate::domain::ports::Repository;
use crate::infrastructure::database::SavedPlaceEntity;

/// Get all saved places as JSON array

pub fn get_all_saved_places() -> Result<String> {
    query_json(|| super::get_context().saved_places_repo.get_all())
}

/// Get a saved place by ID as JSON object

pub fn get_saved_place_by_id(id: i64) -> Result<String> {
    query_json(|| super::get_context().saved_places_repo.get_by_id(id))
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
    eprintln!("[RUST SAVE] Attempting to save place: {}", name);
    command_with_id(|| {
        let ctx = super::get_context();
        let now = chrono::Utc::now().timestamp_millis();
        
        let place = SavedPlaceEntity {
            id: None,
            type_id,
            source: source.unwrap_or_else(|| "manual".to_string()),
            remote_id,
            name,
            address,
            lat,
            lon,
            created_at: now,
        };
        
        eprintln!("[RUST SAVE] Inserting into database...");
        let result = ctx.saved_places_repo.insert(place);
        match &result {
            Ok(id) => eprintln!("[RUST SAVE] Successfully saved with ID: {}", id),
            Err(e) => eprintln!("[RUST SAVE ERROR] Failed to save: {}", e),
        }
        result
    })
}

/// Delete a saved place by ID

pub fn delete_saved_place(id: i64) -> Result<()> {
    command(|| super::get_context().saved_places_repo.delete(id))
}
