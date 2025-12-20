/// Route calculation APIs
use anyhow::Result;

use super::{dto::*, helpers::*};
use crate::domain::value_objects::Position;

/// Calculate a route between waypoints
pub fn calculate_route(waypoints: Vec<(f64, f64)>) -> Result<String> {
    eprintln!(
        "[RUST ROUTE] Calculating route with {} waypoints",
        waypoints.len()
    );
    let result = query_json_async(|| async {
        let ctx = super::get_context();

        let waypoints: Result<Vec<Position>> = waypoints
            .into_iter()
            .map(|(lat, lon)| {
                eprintln!("[RUST ROUTE] Waypoint: {}, {}", lat, lon);
                Position::new(lat, lon)
            })
            .collect();

        eprintln!("[RUST ROUTE] Calling route service");
        let route = match ctx.route_service.calculate_route(waypoints?).await {
            Ok(r) => {
                eprintln!("[RUST ROUTE] Route calculated successfully");
                r
            }
            Err(e) => {
                eprintln!("[RUST ROUTE ERROR] Failed to calculate route: {}", e);
                eprintln!("[RUST ROUTE ERROR] Error chain: {:?}", e);
                return Err(e);
            }
        };
        Ok(route_to_dto(route))
    });

    match &result {
        Ok(_) => eprintln!("[RUST ROUTE] Successfully serialized route"),
        Err(e) => eprintln!("[RUST ROUTE ERROR] Failed in calculate_route: {}", e),
    }

    result
}
