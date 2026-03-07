/// Route calculation APIs
use anyhow::Result;

use crate::api::{dto::*, get_context, helpers::*};
use crate::domain::value_objects::Position;

/// Calculate a route between waypoints
pub fn calculate_route(waypoints: Vec<(f64, f64)>) -> Result<String> {
    query_json_async(|| async {
        let ctx = get_context();

        let waypoints: Result<Vec<Position>> = waypoints
            .into_iter()
            .map(|(lat, lon)| Position::new(lat, lon))
            .collect();

        let route = ctx.route_service.calculate_route(waypoints?).await?;
        Ok(route_to_dto(&route))
    })
}
