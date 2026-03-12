/// Database migration system inspired by Symfony/Doctrine
///
/// Features:
/// - Versioned migrations with up/down support
/// - Automatic tracking of applied migrations
/// - Rollback support
/// - Migration validation
///
/// Each migration is in its own file: m{timestamp}_{description}.rs
use anyhow::{bail, Context, Result};
use rusqlite::{params, Connection};
use std::sync::{Arc, Mutex};

// Migration modules - add new migrations here
mod m20231201000000_initial_schema;
mod m20250212000000_offline_regions;
mod m20250224000000_trips;
mod m20250225000000_saved_routes;
mod m20260307000000_navigation_sessions;
mod m20260309000000_nav_engine_state;

// Re-export migrations (internal use only, not for FFI)
pub use m20231201000000_initial_schema::InitialSchema;

/// Represents a single database migration
pub trait Migration: Send + Sync {
    /// Returns the version number (timestamp recommended: YYYYMMDDHHMMSS)
    fn version(&self) -> i64;

    /// Returns a description of the migration
    fn description(&self) -> &str;

    /// SQL to apply the migration
    fn up(&self) -> &str;

    /// SQL to rollback the migration (optional)
    #[allow(dead_code)]
    fn down(&self) -> Option<&str> {
        None
    }
}

/// Migration manager handles running and tracking migrations
pub struct MigrationManager {
    conn: Arc<Mutex<Connection>>,
}

impl MigrationManager {
    pub fn new(conn: Arc<Mutex<Connection>>) -> Self {
        Self { conn }
    }

    /// Initialize the migrations tracking table
    pub fn initialize(&self) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute(
            "CREATE TABLE IF NOT EXISTS schema_migrations (
                version INTEGER PRIMARY KEY,
                description TEXT NOT NULL,
                applied_at INTEGER NOT NULL
            )",
            [],
        )?;
        Ok(())
    }

    /// Get all applied migration versions
    pub fn get_applied_versions(&self) -> Result<Vec<i64>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare("SELECT version FROM schema_migrations ORDER BY version")?;

        let versions = stmt
            .query_map([], |row| row.get(0))?
            .collect::<Result<Vec<i64>, _>>()?;

        Ok(versions)
    }

    /// Check if a migration has been applied
    pub fn is_applied(&self, version: i64) -> Result<bool> {
        let conn = self.conn.lock().unwrap();
        let count: i64 = conn.query_row(
            "SELECT COUNT(*) FROM schema_migrations WHERE version = ?",
            [version],
            |row| row.get(0),
        )?;
        Ok(count > 0)
    }

    /// Run a single migration
    pub fn migrate_up(&self, migration: &dyn Migration) -> Result<()> {
        let version = migration.version();

        if self.is_applied(version)? {
            println!("Migration {} already applied, skipping", version);
            return Ok(());
        }

        println!(
            "Applying migration {}: {}",
            version,
            migration.description()
        );

        let conn = self.conn.lock().unwrap();

        // Execute migration in a transaction
        conn.execute("BEGIN TRANSACTION", [])?;

        match conn.execute_batch(migration.up()) {
            Ok(_) => {
                // Record the migration
                let now = chrono::Utc::now().timestamp();
                conn.execute(
                    "INSERT INTO schema_migrations (version, description, applied_at) VALUES (?, ?, ?)",
                    params![version, migration.description(), now],
                )?;

                conn.execute("COMMIT", [])?;
                println!("✓ Migration {} applied successfully", version);
                Ok(())
            }
            Err(e) => {
                conn.execute("ROLLBACK", [])?;
                bail!("Failed to apply migration {}: {}", version, e)
            }
        }
    }

    /// Rollback a single migration
    #[allow(dead_code)]
    pub fn migrate_down(&self, migration: &dyn Migration) -> Result<()> {
        let version = migration.version();

        if !self.is_applied(version)? {
            println!("Migration {} not applied, skipping rollback", version);
            return Ok(());
        }

        let down_sql = migration
            .down()
            .context(format!("Migration {} does not support rollback", version))?;

        println!(
            "Rolling back migration {}: {}",
            version,
            migration.description()
        );

        let conn = self.conn.lock().unwrap();

        // Execute rollback in a transaction
        conn.execute("BEGIN TRANSACTION", [])?;

        match conn.execute_batch(down_sql) {
            Ok(_) => {
                // Remove migration record
                conn.execute("DELETE FROM schema_migrations WHERE version = ?", [version])?;

                conn.execute("COMMIT", [])?;
                println!("✓ Migration {} rolled back successfully", version);
                Ok(())
            }
            Err(e) => {
                conn.execute("ROLLBACK", [])?;
                bail!("Failed to rollback migration {}: {}", version, e)
            }
        }
    }

    /// Run all pending migrations
    pub fn migrate(&self, migrations: &[Box<dyn Migration>]) -> Result<()> {
        self.initialize()?;

        let applied = self.get_applied_versions()?;
        let mut pending: Vec<_> = migrations
            .iter()
            .filter(|m| !applied.contains(&m.version()))
            .collect();

        // Sort by version
        pending.sort_by_key(|m| m.version());

        if pending.is_empty() {
            println!("No pending migrations");
            return Ok(());
        }

        println!("Found {} pending migration(s)", pending.len());

        for migration in pending {
            self.migrate_up(migration.as_ref())?;
        }

        println!("All migrations completed successfully");
        Ok(())
    }

    /// Rollback the last N migrations
    #[allow(dead_code)]
    pub fn rollback(&self, migrations: &[Box<dyn Migration>], steps: usize) -> Result<()> {
        let applied = self.get_applied_versions()?;

        if applied.is_empty() {
            println!("No migrations to rollback");
            return Ok(());
        }

        // Get the last N applied versions
        let to_rollback: Vec<i64> = applied.iter().rev().take(steps).copied().collect();

        println!("Rolling back {} migration(s)", to_rollback.len());

        for version in to_rollback {
            if let Some(migration) = migrations.iter().find(|m| m.version() == version) {
                self.migrate_down(migration.as_ref())?;
            } else {
                bail!("Migration {} not found in migration list", version);
            }
        }

        println!("Rollback completed successfully");
        Ok(())
    }

    /// Show migration status
    #[allow(dead_code)]
    pub fn status(&self, migrations: &[Box<dyn Migration>]) -> Result<()> {
        self.initialize()?;

        let applied = self.get_applied_versions()?;

        println!("\n{:<20} {:<10} Description", "Version", "Status");
        println!("{}", "-".repeat(70));

        for migration in migrations {
            let version = migration.version();
            let status = if applied.contains(&version) {
                "Applied"
            } else {
                "Pending"
            };
            println!("{:<20} {:<10} {}", version, status, migration.description());
        }

        println!();
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rusqlite::Connection;

    fn in_memory_conn() -> Arc<Mutex<Connection>> {
        Arc::new(Mutex::new(Connection::open_in_memory().unwrap()))
    }

    struct TestMigration {
        version: i64,
        up_sql: &'static str,
        down_sql: Option<&'static str>,
    }

    impl Migration for TestMigration {
        fn version(&self) -> i64 {
            self.version
        }
        fn description(&self) -> &str {
            "test migration"
        }
        fn up(&self) -> &str {
            self.up_sql
        }
        fn down(&self) -> Option<&str> {
            self.down_sql
        }
    }

    fn make_migration(version: i64, sql: &'static str) -> Box<dyn Migration> {
        Box::new(TestMigration {
            version,
            up_sql: sql,
            down_sql: None,
        })
    }

    fn make_reversible_migration(
        version: i64,
        up: &'static str,
        down: &'static str,
    ) -> Box<dyn Migration> {
        Box::new(TestMigration {
            version,
            up_sql: up,
            down_sql: Some(down),
        })
    }

    #[test]
    fn initialize_creates_schema_migrations_table() {
        let conn = in_memory_conn();
        let mgr = MigrationManager::new(conn.clone());
        mgr.initialize().unwrap();
        let c = conn.lock().unwrap();
        let count: i64 = c.query_row(
            "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='schema_migrations'",
            [],
            |r| r.get(0),
        ).unwrap();
        assert_eq!(count, 1);
    }

    #[test]
    fn migrate_applies_pending_migrations() {
        let conn = in_memory_conn();
        let mgr = MigrationManager::new(conn.clone());
        let migrations: Vec<Box<dyn Migration>> = vec![
            make_migration(1, "CREATE TABLE foo (id INTEGER PRIMARY KEY);"),
            make_migration(2, "CREATE TABLE bar (id INTEGER PRIMARY KEY);"),
        ];
        mgr.migrate(&migrations).unwrap();
        let applied = mgr.get_applied_versions().unwrap();
        assert_eq!(applied, vec![1, 2]);
    }

    #[test]
    fn migrate_is_idempotent() {
        let conn = in_memory_conn();
        let mgr = MigrationManager::new(conn.clone());
        let migrations: Vec<Box<dyn Migration>> = vec![make_migration(
            1,
            "CREATE TABLE foo (id INTEGER PRIMARY KEY);",
        )];
        mgr.migrate(&migrations).unwrap();
        // running again should not fail
        mgr.migrate(&migrations).unwrap();
        assert_eq!(mgr.get_applied_versions().unwrap().len(), 1);
    }

    #[test]
    fn is_applied_returns_false_before_migration() {
        let conn = in_memory_conn();
        let mgr = MigrationManager::new(conn);
        mgr.initialize().unwrap();
        assert!(!mgr.is_applied(99).unwrap());
    }

    #[test]
    fn is_applied_returns_true_after_migration() {
        let conn = in_memory_conn();
        let mgr = MigrationManager::new(conn);
        let migrations: Vec<Box<dyn Migration>> = vec![make_migration(
            42,
            "CREATE TABLE baz (id INTEGER PRIMARY KEY);",
        )];
        mgr.migrate(&migrations).unwrap();
        assert!(mgr.is_applied(42).unwrap());
    }

    #[test]
    fn migrate_down_removes_migration_record() {
        let conn = in_memory_conn();
        let mgr = MigrationManager::new(conn);
        let migrations: Vec<Box<dyn Migration>> = vec![make_reversible_migration(
            10,
            "CREATE TABLE rev_test (id INTEGER PRIMARY KEY);",
            "DROP TABLE rev_test;",
        )];
        mgr.migrate(&migrations).unwrap();
        assert!(mgr.is_applied(10).unwrap());
        mgr.migrate_down(migrations[0].as_ref()).unwrap();
        assert!(!mgr.is_applied(10).unwrap());
    }

    #[test]
    fn rollback_reverts_last_migration() {
        let conn = in_memory_conn();
        let mgr = MigrationManager::new(conn);
        let migrations: Vec<Box<dyn Migration>> = vec![
            make_migration(1, "CREATE TABLE a (id INTEGER PRIMARY KEY);"),
            make_reversible_migration(
                2,
                "CREATE TABLE b (id INTEGER PRIMARY KEY);",
                "DROP TABLE b;",
            ),
        ];
        mgr.migrate(&migrations).unwrap();
        mgr.rollback(&migrations, 1).unwrap();
        assert!(mgr.is_applied(1).unwrap());
        assert!(!mgr.is_applied(2).unwrap());
    }

    #[test]
    fn failed_migration_is_not_recorded() {
        let conn = in_memory_conn();
        let mgr = MigrationManager::new(conn);
        let bad: Vec<Box<dyn Migration>> = vec![make_migration(99, "THIS IS NOT VALID SQL !!!")];
        assert!(mgr.migrate(&bad).is_err());
        mgr.initialize().unwrap(); // re-init since migrate failed before it
        assert!(!mgr.is_applied(99).unwrap());
    }
}

/// Registry of all migrations - ADD NEW MIGRATIONS HERE
pub fn get_all_migrations() -> Vec<Box<dyn Migration>> {
    vec![
        Box::new(InitialSchema {}),
        Box::new(m20250212000000_offline_regions::OfflineRegionsSchema {}),
        Box::new(m20250224000000_trips::TripsSchema {}),
        Box::new(m20250225000000_saved_routes::SavedRoutesSchema {}),
        Box::new(m20260307000000_navigation_sessions::NavigationSessionsSchema {}),
        Box::new(m20260309000000_nav_engine_state::NavEngineStateSchema {}),
    ]
}
