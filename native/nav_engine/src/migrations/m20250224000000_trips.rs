use super::Migration;

pub struct TripsSchema {}

impl Migration for TripsSchema {
    fn version(&self) -> i64 {
        20250224000000
    }

    fn description(&self) -> &str {
        "Create trips table for completed route history"
    }

    fn up(&self) -> &str {
        "
        CREATE TABLE IF NOT EXISTS trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            distance_m REAL NOT NULL,
            duration_seconds INTEGER NOT NULL,
            started_at INTEGER NOT NULL,
            completed_at INTEGER NOT NULL,
            status TEXT NOT NULL,
            destination_label TEXT,
            route_id TEXT,
            polyline_encoded TEXT,
            created_at INTEGER NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_trips_completed_at ON trips(completed_at DESC);
        "
    }

    fn down(&self) -> Option<&str> {
        Some(
            "
        DROP INDEX IF EXISTS idx_trips_completed_at;
        DROP TABLE IF EXISTS trips;
        ",
        )
    }
}
