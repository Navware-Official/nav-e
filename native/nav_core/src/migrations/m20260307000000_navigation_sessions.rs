use super::Migration;

pub struct NavigationSessionsSchema {}

impl Migration for NavigationSessionsSchema {
    fn version(&self) -> i64 {
        20260307000000
    }

    fn description(&self) -> &str {
        "Create navigation_sessions table for persistent navigation state"
    }

    fn up(&self) -> &str {
        "
        CREATE TABLE IF NOT EXISTS navigation_sessions (
            id TEXT PRIMARY KEY,
            route_json TEXT NOT NULL,
            current_lat REAL NOT NULL,
            current_lon REAL NOT NULL,
            status TEXT NOT NULL,
            started_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_navigation_sessions_status ON navigation_sessions(status);
        "
    }

    fn down(&self) -> Option<&str> {
        Some(
            "
        DROP INDEX IF EXISTS idx_navigation_sessions_status;
        DROP TABLE IF EXISTS navigation_sessions;
        ",
        )
    }
}
