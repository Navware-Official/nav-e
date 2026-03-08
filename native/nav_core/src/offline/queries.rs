// Offline region read operations.

#[derive(Debug, Clone)]
pub struct GetAllOfflineRegionsQuery;

#[derive(Debug, Clone)]
pub struct GetOfflineRegionByIdQuery {
    pub id: String,
}

#[derive(Debug, Clone)]
pub struct GetOfflineRegionForViewportQuery {
    pub north: f64,
    pub south: f64,
    pub east: f64,
    pub west: f64,
}

#[derive(Debug, Clone)]
pub struct GetOfflineRegionTileListQuery {
    pub region_id: String,
}

#[derive(Debug, Clone)]
pub struct GetOfflineRegionTileBytesQuery {
    pub region_id: String,
    pub z: i32,
    pub x: i32,
    pub y: i32,
}

#[derive(Debug, Clone)]
pub struct GetStoragePathQuery;
