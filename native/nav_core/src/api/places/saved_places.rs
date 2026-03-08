/// Saved places APIs
use anyhow::Result;

use crate::api::helpers::*;
use crate::app::container::get_container;
use crate::places::commands::*;
use crate::places::queries::*;

/// Get all saved places as JSON array
pub fn get_all_saved_places() -> Result<String> {
    query_json(|| get_container().places.get_all_places(GetAllPlacesQuery))
}

/// Get a saved place by ID as JSON object
pub fn get_saved_place_by_id(id: i64) -> Result<String> {
    query_json(|| get_container().places.get_place_by_id(GetPlaceByIdQuery { id }))
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
    get_container().places.save_place(SavePlaceCommand {
        name,
        address,
        lat,
        lon,
        source,
        type_id,
        remote_id,
    })
}

/// Delete a saved place by ID
pub fn delete_saved_place(id: i64) -> Result<()> {
    get_container().places.delete_place(DeletePlaceCommand { id })
}
