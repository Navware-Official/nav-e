/// Route calculation APIs
use anyhow::Result;

use crate::api::{dto::*, helpers::*};
use crate::app::container::get_container;
use crate::shared::value_objects::Position;

/// Calculate a route between waypoints
pub fn calculate_route(waypoints: Vec<(f64, f64)>) -> Result<String> {
    query_json_async(|| async {
        let waypoints: Result<Vec<Position>> = waypoints
            .into_iter()
            .map(|(lat, lon)| Position::new(lat, lon))
            .collect();

        let route = get_container()
            .navigation
            .calculate_route(waypoints?)
            .await?;
        Ok(route_to_dto(&route))
    })
}
