/// Saved routes API - import from GPX, save from plan, CRUD
use anyhow::Result;
use chrono::Utc;
use geo_types::Coord;
use nav_ir::Route as NavIrRoute;

use super::helpers::*;
use crate::domain::ports::Repository;
use crate::infrastructure::database::SavedRouteEntity;

/// Parse GPX bytes into Nav-IR route JSON without saving. Use for preview-before-save flow.
pub fn parse_route_from_gpx(bytes: &[u8]) -> Result<String> {
    let route = nav_ir::normalize_gpx(bytes).map_err(|e| anyhow::anyhow!("{}", e))?;
    serde_json::to_string(&route).map_err(Into::into)
}

/// Save a pre-parsed route (Nav-IR JSON) to the database. Validates JSON and extracts name from metadata.
pub fn save_route_from_json(route_json: &str, source: String) -> Result<String> {
    let route: NavIrRoute = serde_json::from_str(route_json)
        .map_err(|e| anyhow::anyhow!("Invalid route JSON: {}", e))?;
    route.validate().map_err(|e| anyhow::anyhow!("{}", e))?;
    let name = route.metadata.name.clone();
    let now = Utc::now().timestamp();
    let id = command_with_id(|| {
        let ctx = super::get_context();
        let entity = SavedRouteEntity {
            id: None,
            name,
            route_json: route_json.to_string(),
            source,
            created_at: now,
        };
        ctx.saved_routes_repo.insert(entity)
    })?;
    let entity = super::get_context()
        .saved_routes_repo
        .get_by_id(id)?
        .ok_or_else(|| anyhow::anyhow!("Saved route not found after insert"))?;
    Ok(serde_json::to_string(&entity)?)
}

/// Import a route from GPX bytes, persist it, and return the saved route as JSON.
pub fn import_route_from_gpx(bytes: &[u8]) -> Result<String> {
    let route = nav_ir::normalize_gpx(bytes).map_err(|e| anyhow::anyhow!("{}", e))?;
    let name = route.metadata.name.clone();
    let route_json = serde_json::to_string(&route)?;
    let now = Utc::now().timestamp();
    let id = command_with_id(|| {
        let ctx = super::get_context();
        let entity = SavedRouteEntity {
            id: None,
            name,
            route_json,
            source: "gpx".to_string(),
            created_at: now,
        };
        ctx.saved_routes_repo.insert(entity)
    })?;
    let entity = super::get_context()
        .saved_routes_repo
        .get_by_id(id)?
        .ok_or_else(|| anyhow::anyhow!("Saved route not found after insert"))?;
    Ok(serde_json::to_string(&entity)?)
}

/// Build a Nav-IR route from plan data (waypoints + optional polyline), persist it, return the new row id.
/// If polyline_encoded is None or empty, encodes waypoints as a polyline.
pub fn save_route_from_plan(
    name: String,
    waypoints: Vec<(f64, f64)>,
    polyline_encoded: Option<String>,
    distance_m: Option<f64>,
    duration_s: Option<u64>,
) -> Result<i64> {
    if waypoints.len() < 2 {
        anyhow::bail!("Need at least two waypoints (Start and Stop)");
    }
    let polyline_str = match polyline_encoded.as_deref() {
        Some(s) if !s.is_empty() => s.to_string(),
        _ => {
            let coords: Vec<Coord<f64>> = waypoints
                .iter()
                .map(|(lat, lon)| Coord { x: *lon, y: *lat })
                .collect();
            polyline::encode_coordinates(coords, 5).map_err(|e| anyhow::anyhow!("{}", e))?
        }
    };
    let route = nav_ir::normalize_custom(&waypoints, &polyline_str, distance_m, duration_s)
        .map_err(|e| anyhow::anyhow!("{}", e))?;
    let mut route = route;
    route.metadata.name = name;
    let route_json = serde_json::to_string(&route)?;
    let now = Utc::now().timestamp();
    command_with_id(|| {
        let ctx = super::get_context();
        let entity = SavedRouteEntity {
            id: None,
            name: route.metadata.name.clone(),
            route_json,
            source: "plan".to_string(),
            created_at: now,
        };
        ctx.saved_routes_repo.insert(entity)
    })
}

/// Get all saved routes as JSON array (newest first).
pub fn get_all_saved_routes() -> Result<String> {
    query_json(|| super::get_context().saved_routes_repo.get_all())
}

/// Get a saved route by ID as JSON object (or null string if not found).
pub fn get_saved_route_by_id(id: i64) -> Result<String> {
    query_json(|| super::get_context().saved_routes_repo.get_by_id(id))
}

/// Delete a saved route by ID.
pub fn delete_saved_route(id: i64) -> Result<()> {
    command(|| super::get_context().saved_routes_repo.delete(id))
}
