// Offline region write operations.

#[derive(Debug, Clone)]
pub struct DownloadOfflineRegionCommand {
    /// Gateway-side region identifier (e.g. `"netherlands"`).
    pub region_id: String,
}

#[derive(Debug, Clone)]
pub struct DeleteOfflineRegionCommand {
    pub id: String,
}
