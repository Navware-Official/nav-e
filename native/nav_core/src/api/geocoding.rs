/// Geocoding APIs
use anyhow::Result;

use super::dto::GeocodingResultDto;
use crate::application::{handlers::*, queries::*};
use crate::domain::value_objects::*;

/// Search for locations by address/name
pub fn geocode_search(query: String, limit: Option<u32>) -> Result<String> {
    let results = super::block_on(async {
        let ctx = super::get_context();
        let handler = GeocodeHandler::new(ctx.geocoding_service.clone());
        handler
            .handle(GeocodeQuery {
                address: query,
                limit,
            })
            .await
    })?;

    let dtos: Vec<GeocodingResultDto> = results.into_iter().map(GeocodingResultDto::from).collect();
    Ok(serde_json::to_string(&dtos)?)
}

/// Reverse geocode coordinates to address
pub fn reverse_geocode(latitude: f64, longitude: f64) -> Result<String> {
    super::block_on(async {
        let ctx = super::get_context();
        let handler = ReverseGeocodeHandler::new(ctx.geocoding_service.clone());
        let position = Position::new(latitude, longitude).map_err(|e| anyhow::anyhow!(e))?;
        let query = ReverseGeocodeQuery { position };
        handler.handle(query).await
    })
}
