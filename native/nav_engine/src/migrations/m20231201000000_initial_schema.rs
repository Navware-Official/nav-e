use super::Migration;

pub struct InitialSchema {}

impl Migration for InitialSchema {
    fn version(&self) -> i64 {
        20231201000000 // YYYYMMDDHHMMSS format
    }

    fn description(&self) -> &str {
        "Create initial schema with saved_places and devices tables"
    }

    fn up(&self) -> &str {
        "
        CREATE TABLE IF NOT EXISTS saved_places (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type_id INTEGER,
            source TEXT NOT NULL,
            remote_id TEXT,
            name TEXT NOT NULL,
            address TEXT,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            created_at INTEGER NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_saved_places_created_at ON saved_places(created_at);

        CREATE TABLE IF NOT EXISTS devices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            remote_id TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            device_type TEXT NOT NULL,
            connection_type TEXT NOT NULL,
            paired INTEGER NOT NULL DEFAULT 0,
            last_connected INTEGER,
            firmware_version TEXT,
            battery_level INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_devices_remote_id ON devices(remote_id);
        CREATE INDEX IF NOT EXISTS idx_devices_name ON devices(name);
        "
    }

    fn down(&self) -> Option<&str> {
        Some("
        DROP INDEX IF EXISTS idx_devices_name;
        DROP INDEX IF EXISTS idx_devices_remote_id;
        DROP TABLE IF EXISTS devices;
        DROP INDEX IF EXISTS idx_saved_places_created_at;
        DROP TABLE IF EXISTS saved_places;
        ")
    }
}
