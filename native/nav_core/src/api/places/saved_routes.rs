/// Saved routes API - import from GPX, save from plan, CRUD
use anyhow::Result;

use crate::api::helpers::*;
use crate::app::container::get_container;
use crate::places::commands::*;
use crate::places::queries::*;

/// Parse GPX bytes into Nav-IR route JSON without saving. Use for preview-before-save flow.
pub fn parse_route_from_gpx(bytes: &[u8]) -> Result<String> {
    let route = get_container()
        .places
        .parse_route_from_gpx(ParseRouteFromGpxQuery {
            bytes: bytes.to_vec(),
        })?;
    serde_json::to_string(&route).map_err(Into::into)
}

/// Save a pre-parsed route (Nav-IR JSON) to the database. Returns the saved entity as JSON.
pub fn save_route_from_json(route_json: &str, source: String) -> Result<String> {
    query_json(|| {
        get_container()
            .places
            .save_route_from_json(SaveRouteFromJsonCommand {
                route_json: route_json.to_string(),
                source,
            })
    })
}

/// Import a route from GPX bytes, persist it, and return the saved route as JSON.
pub fn import_route_from_gpx(bytes: &[u8]) -> Result<String> {
    query_json(|| {
        get_container()
            .places
            .import_route_from_gpx(ImportRouteFromGpxCommand {
                bytes: bytes.to_vec(),
            })
    })
}

/// Build the current plan-route (waypoints + polyline) as a saved route. Returns the new row id.
pub fn save_route_from_plan(
    name: String,
    waypoints: Vec<(f64, f64)>,
    polyline_encoded: Option<String>,
    distance_m: Option<f64>,
    duration_s: Option<u64>,
) -> Result<i64> {
    get_container()
        .places
        .save_route_from_plan(SaveRouteFromPlanCommand {
            name,
            waypoints,
            polyline_encoded,
            distance_m,
            duration_s,
        })
}

/// Get all saved routes as JSON array (newest first).
pub fn get_all_saved_routes() -> Result<String> {
    query_json(|| {
        get_container()
            .places
            .get_all_saved_routes(GetAllSavedRoutesQuery)
    })
}

/// Get a saved route by ID as JSON object (or null if not found).
pub fn get_saved_route_by_id(id: i64) -> Result<String> {
    query_json(|| {
        get_container()
            .places
            .get_saved_route_by_id(GetSavedRouteByIdQuery { id })
    })
}

/// Delete a saved route by ID.
pub fn delete_saved_route(id: i64) -> Result<()> {
    get_container()
        .places
        .delete_saved_route(DeleteSavedRouteCommand { id })
}
