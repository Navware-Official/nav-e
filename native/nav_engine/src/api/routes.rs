/// Route calculation APIs
use anyhow::Result;

use super::{helpers::*, dto::*};
use crate::application::queries::*;
use crate::domain::value_objects::Position;

/// Calculate a route between waypoints

pub fn calculate_route(waypoints: Vec<(f64, f64)>) -> Result<String> {
    eprintln!("[RUST ROUTE] Calculating route with {} waypoints", waypoints.len());
    query_json_async(|| async {
        let ctx = super::get_context();
        
        let waypoints: Result<Vec<Position>> = waypoints
            .into_iter()
            .map(|(lat, lon)| {
                eprintln!("[RUST ROUTE] Waypoint: {}, {}", lat, lon);
                Position::new(lat, lon)
            })
            .collect();
        
        eprintln!("[RUST ROUTE] Calling route service");
        let route = ctx.route_service.calculate_route(waypoints?).await?;
        eprintln!("[RUST ROUTE] Route calculated successfully");
        Ok(route_to_dto(route))
    })
}
