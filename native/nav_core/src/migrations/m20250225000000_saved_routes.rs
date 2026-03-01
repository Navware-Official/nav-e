use super::Migration;

pub struct SavedRoutesSchema {}

impl Migration for SavedRoutesSchema {
    fn version(&self) -> i64 {
        20250225000000
    }

    fn description(&self) -> &str {
        "Create saved_routes table for imported and saved routes"
    }

    fn up(&self) -> &str {
        "
        CREATE TABLE IF NOT EXISTS saved_routes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            route_json TEXT NOT NULL,
            source TEXT NOT NULL,
            created_at INTEGER NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_saved_routes_created_at ON saved_routes(created_at DESC);
        "
    }

    fn down(&self) -> Option<&str> {
        Some(
            "
        DROP INDEX IF EXISTS idx_saved_routes_created_at;
        DROP TABLE IF EXISTS saved_routes;
        ",
        )
    }
}
