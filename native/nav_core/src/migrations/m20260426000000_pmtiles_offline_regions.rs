use super::Migration;

/// Switches offline regions from per-tile XYZ directories to single-file PMTiles archives.
///
/// Existing rows are dropped — they reference the old tile-tree layout that this build
/// no longer reads. The orphaned directories on disk are harmless and can be cleaned up
/// later if it matters; the user is expected to re-download.
pub struct PmTilesOfflineRegions {}

impl Migration for PmTilesOfflineRegions {
    fn version(&self) -> i64 {
        20260426000000
    }

    fn description(&self) -> &str {
        "Move offline regions to PMTiles archive storage"
    }

    fn up(&self) -> &str {
        "
        DELETE FROM offline_regions;
        ALTER TABLE offline_regions ADD COLUMN region_id TEXT NOT NULL DEFAULT '';
        "
    }

    fn down(&self) -> Option<&str> {
        Some(
            "
        DELETE FROM offline_regions;
        ALTER TABLE offline_regions DROP COLUMN region_id;
        ",
        )
    }
}
