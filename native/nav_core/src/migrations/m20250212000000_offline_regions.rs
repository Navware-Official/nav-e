use super::Migration;

pub struct OfflineRegionsSchema {}

impl Migration for OfflineRegionsSchema {
    fn version(&self) -> i64 {
        20250212000000
    }

    fn description(&self) -> &str {
        "Create offline_regions table for downloaded map regions"
    }

    fn up(&self) -> &str {
        "
        CREATE TABLE IF NOT EXISTS offline_regions (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            north REAL NOT NULL,
            south REAL NOT NULL,
            east REAL NOT NULL,
            west REAL NOT NULL,
            min_zoom INTEGER NOT NULL,
            max_zoom INTEGER NOT NULL,
            relative_path TEXT NOT NULL,
            size_bytes INTEGER NOT NULL,
            created_at INTEGER NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_offline_regions_created_at ON offline_regions(created_at);
        "
    }

    fn down(&self) -> Option<&str> {
        Some(
            "
        DROP INDEX IF EXISTS idx_offline_regions_created_at;
        DROP TABLE IF EXISTS offline_regions;
        ",
        )
    }
}
