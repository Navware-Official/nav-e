use super::Migration;

pub struct NavEngineStateSchema {}

impl Migration for NavEngineStateSchema {
    fn version(&self) -> i64 {
        20260309000000
    }

    fn description(&self) -> &str {
        "Add nav_engine step/distance columns to navigation_sessions"
    }

    fn up(&self) -> &str {
        "
        ALTER TABLE navigation_sessions ADD COLUMN current_step_index INTEGER DEFAULT 0;
        ALTER TABLE navigation_sessions ADD COLUMN distance_traveled_m REAL DEFAULT 0.0;
        "
    }

    fn down(&self) -> Option<&str> {
        // SQLite does not support DROP COLUMN on older versions; leave as-is on rollback
        None
    }
}
