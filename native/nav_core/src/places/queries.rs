// Place, Trip, and SavedRoute read operations.
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GetAllPlacesQuery;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GetPlaceByIdQuery {
    pub id: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GetAllTripsQuery;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GetTripByIdQuery {
    pub id: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GetAllSavedRoutesQuery;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GetSavedRouteByIdQuery {
    pub id: i64,
}

#[derive(Debug, Clone)]
pub struct ParseRouteFromGpxQuery {
    pub bytes: Vec<u8>,
}
