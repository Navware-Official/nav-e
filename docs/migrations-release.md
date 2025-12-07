# Release Process & Database Migrations

## Overview

Database migrations in Nav-E run **automatically** when the app starts via `Database::new()`. This ensures that:
- ✅ Users always have the latest schema
- ✅ No manual intervention needed on app updates
- ✅ Safe, transactional migrations
- ✅ Automatic rollback on failure

## Migration Lifecycle

### Development Phase

1. **Create a new migration:**
   ```bash
   make migrate-new
   ```
   - Generates a timestamped migration template
   - Prompts for description
   - Creates struct name automatically

2. **Implement the migration:**
   - Add SQL to `up()` method
   - Add rollback SQL to `down()` (optional but recommended)
   - Register in `get_all_migrations()`

3. **Test locally:**
   ```bash
   make codegen
   flutter run
   ```
   - Migration runs automatically on app start
   - Check logs for: "✓ Migration {version} applied successfully"

4. **Verify migration:**
   ```bash
   make migrate-status
   ```
   - Shows all defined migrations
   - Applied migrations tracked in `schema_migrations` table

### Release Phase

When creating a new version release:

1. **Update version in `pubspec.yaml`:**
   ```yaml
   version: 1.1.0+2  # Increment version
   ```

2. **Create git tag:**
   ```bash
   git tag -a v1.1.0 -m "Release v1.1.0: Add user settings feature"
   git push origin v1.1.0
   ```

3. **Migrations run automatically:**
   - On app update, `Database::new()` checks for pending migrations
   - Applies them in version order
   - Users see no interruption (migrations run in milliseconds)

### Production Deployment

No special migration steps needed! The migration system:
- ✅ Detects pending migrations on app start
- ✅ Applies them transactionally
- ✅ Records successful migrations
- ✅ Skips already-applied migrations (idempotent)

## Migration Best Practices for Releases

### DO:
- ✅ Test migrations locally before tagging release
- ✅ Keep migrations small and focused
- ✅ Include rollback SQL in `down()` method
- ✅ Use descriptive migration names
- ✅ Document breaking schema changes in release notes
- ✅ Version migrations with timestamp (YYYYMMDDHHMMSS)

### DON'T:
- ❌ Modify existing migrations after release
- ❌ Skip version numbers
- ❌ Include data-dependent migrations without validation
- ❌ Forget to register new migrations in `get_all_migrations()`

## Example Release Workflow

### Scenario: Adding a "favorites" feature in v1.2.0

1. **Create migration:**
   ```bash
   make migrate-new
   # Enter: "add favorites table"
   ```

2. **Implement migration:**
   ```rust
   // In migrations.rs
   #[flutter_rust_bridge::frb(ignore)]
   pub struct AddFavoritesTable {}

   impl Migration for AddFavoritesTable {
       fn version(&self) -> i64 { 20241207160000 }
       
       fn description(&self) -> &str {
           "add favorites table"
       }
       
       fn up(&self) -> &str {
           "
           CREATE TABLE favorites (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               place_id INTEGER NOT NULL,
               user_id INTEGER,
               created_at INTEGER NOT NULL,
               FOREIGN KEY (place_id) REFERENCES saved_places(id)
           );
           CREATE INDEX idx_favorites_place_id ON favorites(place_id);
           "
       }
       
       fn down(&self) -> Option<&str> {
           Some("
           DROP INDEX IF EXISTS idx_favorites_place_id;
           DROP TABLE IF EXISTS favorites;
           ")
       }
   }
   ```

3. **Register migration:**
   ```rust
   pub fn get_all_migrations() -> Vec<Box<dyn Migration>> {
       vec![
           Box::new(InitialSchema {}),
           Box::new(AddFavoritesTable {}),  // Add here
       ]
   }
   ```

4. **Test locally:**
   ```bash
   make codegen
   flutter run
   # Check logs for migration success
   ```

5. **Commit and release:**
   ```bash
   git add .
   git commit -m "feat: Add favorites feature with database migration"
   
   # Update pubspec.yaml version to 1.2.0+3
   
   git tag -a v1.2.0 -m "Release v1.2.0: Add favorites feature"
   git push origin main v1.2.0
   ```

6. **Users update app:**
   - Download update from store
   - Open app
   - Migration runs automatically in background
   - Favorites feature ready to use!

## Monitoring & Debugging

### Check migration history:
```sql
SELECT 
    version,
    description,
    datetime(applied_at, 'unixepoch') as applied_at
FROM schema_migrations
ORDER BY version;
```

### View logs:
Migrations print to console:
```
Applying migration 20241207160000: add favorites table
✓ Migration 20241207160000 applied successfully
```

### Rollback (if needed):
Rollback is not exposed via Makefile but available in code:
```rust
// In Database or test code
let manager = MigrationManager::new(db.get_connection());
let migrations = get_all_migrations();
manager.rollback(&migrations, 1)?;  // Rollback last migration
```

## Migration Version Format

Use timestamp format: `YYYYMMDDHHMMSS`

Examples:
- `20241207160000` = December 7, 2024, 16:00:00
- `20241225093000` = December 25, 2024, 09:30:00

**Why timestamp?**
- ✅ Chronological ordering guaranteed
- ✅ No conflicts in team development
- ✅ Easy to trace when schema changed
- ✅ Matches industry standards (Symfony, Laravel, Rails)

Generate automatically:
```bash
date +%Y%m%d%H%M%S
# Output: 20241207160525
```

## CI/CD Integration

Add to your CI/CD pipeline:

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Verify migrations
        run: |
          make migrate-status
          
      - name: Build app
        run: |
          flutter build apk --release
          
      - name: Create release
        # ... upload to store
```

## FAQ

**Q: What if a migration fails on a user's device?**
A: The migration runs in a transaction and auto-rolls back. The app will show an error and user can report it. Fix and release a patch version.

**Q: Can I skip migrations?**
A: No, migrations run in order by version number. All pending migrations must be applied.

**Q: What if I need to change an already-released migration?**
A: Never modify released migrations. Create a new migration to alter the schema.

**Q: Do migrations slow down app startup?**
A: No, already-applied migrations are skipped immediately. Only new migrations run (usually <50ms).

**Q: How do I test migrations on different database states?**
A: Delete the app data and reinstall. All migrations will run in sequence from scratch.

## Summary

✅ **Migrations are automatic** - No manual database updates needed
✅ **Version-controlled** - All schema changes tracked in git
✅ **Safe** - Transactional with auto-rollback
✅ **Team-friendly** - Timestamp versioning prevents conflicts
✅ **Production-ready** - Runs seamlessly on app updates

---

For more details on creating migrations, see:
- [MIGRATIONS.md](native/nav_engine/src/MIGRATIONS.md)
- Migration system code: `native/nav_engine/src/migrations.rs`
