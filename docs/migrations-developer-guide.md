# Database Migrations - Developer Guide

Complete guide for creating and managing database migrations in Nav-E.

## Overview

Nav-E uses a Symfony/Doctrine-inspired migration system with:
- ✅ **Automatic execution** - Migrations run on app start
- ✅ **Version control** - Timestamp-based versioning (YYYYMMDDHHMMSS)
- ✅ **Modular structure** - Each migration in its own file
- ✅ **Transaction safety** - Auto-rollback on failure
- ✅ **Rollback support** - Optional `down()` methods

## File Structure

```
native/nav_engine/src/migrations/
├── mod.rs                                    # Registry & trait definition
├── m20231201000000_initial_schema.rs        # Initial migration
└── m{timestamp}_{description}.rs            # Your migrations
```

Each migration file follows the naming pattern: `m{timestamp}_{snake_case_description}.rs`

## Creating a Migration

### Quick Start

```bash
make migrate-new
# Enter description: "add user settings table"
# ✅ File created: migrations/m20241207170530_add_user_settings_table.rs
# ✅ Automatically registered in mod.rs
# ✅ Automatically added to get_all_migrations()
```

### What Gets Generated

The command creates a complete migration file:

```rust
// migrations/m20241207170530_add_user_settings_table.rs
use super::Migration;

#[flutter_rust_bridge::frb(ignore)]
pub struct AddUserSettingsTable {}

impl Migration for AddUserSettingsTable {
    fn version(&self) -> i64 {
        20241207170530
    }

    fn description(&self) -> &str {
        "add user settings table"
    }

    fn up(&self) -> &str {
        "
        -- Add your SQL here
        CREATE TABLE user_settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key TEXT NOT NULL UNIQUE,
            value TEXT NOT NULL,
            created_at INTEGER NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_user_settings_key ON user_settings(key);
        "
    }

    fn down(&self) -> Option<&str> {
        Some("
        -- Rollback SQL
        DROP INDEX IF EXISTS idx_user_settings_key;
        DROP TABLE IF EXISTS user_settings;
        ")
    }
}
```

### Auto-Registration

The script automatically updates `mod.rs`:

```rust
// Added automatically
mod m20241207170530_add_user_settings_table;
pub use m20241207170530_add_user_settings_table::AddUserSettingsTable;

pub fn get_all_migrations() -> Vec<Box<dyn Migration>> {
    vec![
        Box::new(InitialSchema {}),
        Box::new(AddUserSettingsTable {}),  // Added automatically
    ]
}
```

## Migration Trait

All migrations implement the `Migration` trait:

```rust
pub trait Migration: Send + Sync {
    /// Version number (YYYYMMDDHHMMSS timestamp)
    fn version(&self) -> i64;
    
    /// Human-readable description
    fn description(&self) -> &str;
    
    /// SQL to apply migration (required)
    fn up(&self) -> &str;
    
    /// SQL to rollback (optional, returns None by default)
    fn down(&self) -> Option<&str> {
        None
    }
}
```

## Version Numbering

Use timestamp format: `YYYYMMDDHHMMSS`

```bash
# Generate version number
date +%Y%m%d%H%M%S
# Output: 20241207170530
```

**Why timestamps?**
- ✅ Chronological ordering guaranteed
- ✅ No conflicts in team development
- ✅ Easy to trace when schema changed
- ✅ Industry standard (Symfony, Laravel, Rails)

## Writing Migration SQL

### Best Practices

```rust
fn up(&self) -> &str {
    "
    -- Use IF NOT EXISTS for safety
    CREATE TABLE IF NOT EXISTS example (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
    );

    -- Always create indexes
    CREATE INDEX IF NOT EXISTS idx_example_name ON example(name);

    -- Use transactions (handled automatically by framework)
    "
}
```

### Common Operations

#### Creating a Table
```rust
fn up(&self) -> &str {
    "
    CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        created_at INTEGER NOT NULL
    );
    "
}
```

#### Adding a Column
```rust
fn up(&self) -> &str {
    "ALTER TABLE users ADD COLUMN email TEXT;"
}

fn down(&self) -> Option<&str> {
    Some("ALTER TABLE users DROP COLUMN email;")
}
```

#### Creating an Index
```rust
fn up(&self) -> &str {
    "CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);"
}

fn down(&self) -> Option<&str> {
    Some("DROP INDEX IF EXISTS idx_users_email;")
}
```

#### Data Migration
```rust
fn up(&self) -> &str {
    "
    -- Normalize existing data
    UPDATE users SET email = LOWER(email);
    "
}

fn down(&self) -> Option<&str> {
    None  // Cannot reliably undo data transformations
}
```

## Testing Migrations

### Local Testing

```bash
# 1. Create migration
make migrate-new

# 2. Edit the SQL

# 3. Rebuild
make codegen

# 4. Run app (migration runs automatically)
flutter run

# 5. Check logs for:
# ✓ Migration 20241207170530 applied successfully
```

### Testing Rollback

Rollback is not exposed via CLI but can be tested in Rust:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_migration_rollback() {
        let db = Database::new_in_memory().unwrap();
        let manager = MigrationManager::new(db.get_connection());
        
        let migration = AddUserSettingsTable {};
        manager.migrate_up(&migration).unwrap();
        manager.migrate_down(&migration).unwrap();
    }
}
```

## Viewing Migration Status

```bash
make migrate-status
```

Output:
```
Migration status:
Migrations are applied automatically when the app starts via Database::new()

Defined migrations:
  m20231201000000_initial_schema
  m20241207170530_add_user_settings_table

To create a new migration: make migrate-new
```

## How Migrations Run

Migrations execute automatically when `Database::new()` is called:

```rust
impl Database {
    pub fn new(db_path: PathBuf) -> Result<Self> {
        let conn = Connection::open(db_path)?;
        let db = Self { conn: Arc::new(Mutex::new(conn)) };
        
        // Migrations run here
        let manager = MigrationManager::new(db.get_connection());
        let migrations = get_all_migrations();
        manager.migrate(&migrations)?;
        
        Ok(db)
    }
}
```

The migration manager:
1. Creates `schema_migrations` tracking table
2. Queries which migrations are already applied
3. Runs pending migrations in version order
4. Records successful migrations
5. Skips already-applied migrations

## Tracking Table

Migrations are tracked in `schema_migrations`:

```sql
CREATE TABLE schema_migrations (
    version INTEGER PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at INTEGER NOT NULL
);
```

Query migration history:
```sql
SELECT 
    version,
    description,
    datetime(applied_at, 'unixepoch') as applied_at
FROM schema_migrations
ORDER BY version;
```

## Best Practices

### DO ✅
- Test migrations locally before committing
- Use `IF NOT EXISTS` and `IF EXISTS` clauses
- Include rollback SQL in `down()` method
- Keep migrations small and focused
- Use descriptive names
- Add comments to complex SQL
- Commit migrations with related code changes

### DON'T ❌
- Don't modify existing migrations after they're committed
- Don't skip version numbers
- Don't include app-specific logic in migrations
- Don't forget to run `make codegen` after creating migration
- Don't commit incomplete migrations

## Common Patterns

### Foreign Keys
```rust
fn up(&self) -> &str {
    "
    CREATE TABLE orders (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
    );
    "
}
```

### Unique Constraints
```rust
fn up(&self) -> &str {
    "
    CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        email TEXT NOT NULL UNIQUE
    );
    "
}
```

### Multi-column Indexes
```rust
fn up(&self) -> &str {
    "
    CREATE INDEX idx_orders_user_date 
    ON orders(user_id, created_at);
    "
}
```

## Troubleshooting

### Migration Failed

Migrations run in transactions and auto-rollback on failure:
```
Failed to apply migration 20241207170530: ...
```

**Solution:**
1. Check the error message
2. Fix the SQL in your migration file
3. Delete the app data (to reset database)
4. Run `flutter run` again

### Already Applied

If you need to re-run a migration:
```sql
DELETE FROM schema_migrations WHERE version = 20241207170530;
```

Then restart the app.

### Version Conflict

If two developers create migrations at the same time:
- Rename the later migration file
- Update the `version()` method
- Re-register in `mod.rs`
- Rebuild with `make codegen`

## Advanced Usage

### Conditional Migrations

```rust
fn up(&self) -> &str {
    "
    -- Only add column if it doesn't exist
    -- (SQLite doesn't support IF NOT EXISTS for ALTER TABLE)
    CREATE TABLE IF NOT EXISTS users_new (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT  -- new column
    );
    
    INSERT INTO users_new SELECT id, name, NULL FROM users;
    DROP TABLE users;
    ALTER TABLE users_new RENAME TO users;
    "
}
```

### Large Data Migrations

For migrations that touch many rows:
```rust
fn up(&self) -> &str {
    "
    -- Process in batches (theoretical, SQLite does this automatically)
    UPDATE users SET normalized_name = LOWER(name);
    "
}
```

## Summary

Creating migrations in Nav-E is simple:

1. **Create**: `make migrate-new`
2. **Edit**: Add your SQL to the generated file
3. **Build**: `make codegen`
4. **Test**: `flutter run`

That's it! Migrations run automatically and safely. 🎉

---

For release workflow and production deployment, see [Migrations: Release Process](migrations-release.md).
