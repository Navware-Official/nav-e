// Offline region write operations.

#[derive(Debug, Clone)]
pub struct DownloadOfflineRegionCommand {
    pub name: String,
    pub north: f64,
    pub south: f64,
    pub east: f64,
    pub west: f64,
    pub min_zoom: i32,
    pub max_zoom: i32,
    pub tile_url_template: Option<String>,
}

#[derive(Debug, Clone)]
pub struct DeleteOfflineRegionCommand {
    pub id: String,
}
