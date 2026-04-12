/// Geocoding APIs
use anyhow::Result;

use super::dto::GeocodingResultDto;
use super::helpers::block_on;
use crate::app::container::get_container;
use crate::navigation::application::queries::*;
use crate::shared::value_objects::*;

/// Search for locations by address/name
pub fn geocode_search(query: String, limit: Option<u32>) -> Result<Vec<GeocodingResultDto>> {
    let results = block_on(async {
        get_container()
            .geocoding
            .geocode(GeocodeQuery {
                address: query,
                limit,
            })
            .await
    })?;

    Ok(results.into_iter().map(GeocodingResultDto::from).collect())
}

/// Reverse geocode coordinates to address
pub fn reverse_geocode(latitude: f64, longitude: f64) -> Result<String> {
    block_on(async {
        let position = Position::new(latitude, longitude).map_err(|e| anyhow::anyhow!(e))?;
        get_container()
            .geocoding
            .reverse_geocode(ReverseGeocodeQuery { position })
            .await
    })
}
