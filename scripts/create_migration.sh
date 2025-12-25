#!/bin/bash
# Script to create a new database migration file
# Usage: make migrate-new

# Get migration description from user
echo "Creating a new database migration..."
echo ""
read -p "Enter migration description (e.g., 'add user settings table'): " description

if [ -z "$description" ]; then
    echo "Error: Migration description cannot be empty"
    exit 1
fi

# Generate timestamp version (YYYYMMDDHHMMSS)
VERSION=$(date +%Y%m%d%H%M%S)

# Convert description to snake_case for filename
SNAKE_CASE=$(echo "$description" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9 ]//g' | \
    sed 's/ /_/g')

# Convert description to CamelCase struct name
STRUCT_NAME=$(echo "$description" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9 ]//g' | \
    sed 's/\b\(.\)/\u\1/g' | \
    sed 's/ //g')

# Ensure first letter is uppercase
STRUCT_NAME="$(tr '[:lower:]' '[:upper:]' <<< ${STRUCT_NAME:0:1})${STRUCT_NAME:1}"

# File paths
MIGRATIONS_DIR="native/nav_engine/src/migrations"
MIGRATION_FILE="${MIGRATIONS_DIR}/m${VERSION}_${SNAKE_CASE}.rs"
MOD_FILE="${MIGRATIONS_DIR}/mod.rs"

# Create the migration file
cat > "$MIGRATION_FILE" << 'MIGRATION_EOF'
use super::Migration;

#[flutter_rust_bridge::frb(ignore)]
pub struct STRUCT_NAME_PLACEHOLDER {}

impl Migration for STRUCT_NAME_PLACEHOLDER {
    fn version(&self) -> i64 {
        VERSION_PLACEHOLDER
    }

    fn description(&self) -> &str {
        "DESCRIPTION_PLACEHOLDER"
    }

    fn up(&self) -> &str {
        "
        -- Add your SQL here
        -- Example:
        -- CREATE TABLE example (
        --     id INTEGER PRIMARY KEY AUTOINCREMENT,
        --     name TEXT NOT NULL,
        --     created_at INTEGER NOT NULL
        -- );
        -- CREATE INDEX IF NOT EXISTS idx_example_name ON example(name);
        "
    }

    fn down(&self) -> Option<&str> {
        Some("
        -- Add rollback SQL here (optional but recommended)
        -- Example:
        -- DROP INDEX IF EXISTS idx_example_name;
        -- DROP TABLE IF EXISTS example;
        ")
    }
}
MIGRATION_EOF

# Replace placeholders
sed -i "s/STRUCT_NAME_PLACEHOLDER/$STRUCT_NAME/g" "$MIGRATION_FILE"
sed -i "s/VERSION_PLACEHOLDER/$VERSION/g" "$MIGRATION_FILE"
sed -i "s/DESCRIPTION_PLACEHOLDER/$description/g" "$MIGRATION_FILE"

# Add module declaration to mod.rs (after the existing mod declarations)
MODULE_NAME="m${VERSION}_${SNAKE_CASE}"
sed -i "/^mod m[0-9]/a mod $MODULE_NAME;" "$MOD_FILE"

# Add to exports (after existing pub use statements)
sed -i "/^pub use m[0-9]/a pub use ${MODULE_NAME}::${STRUCT_NAME};" "$MOD_FILE"

# Add to get_all_migrations() registry (before the closing comment)
sed -i "/\/\/ Add new migrations below/a \        Box::new(${STRUCT_NAME} {})," "$MOD_FILE"

echo ""
echo "✅ Migration created successfully!"
echo ""
echo "📄 File: $MIGRATION_FILE"
echo "🔢 Version: $VERSION"
echo "📝 Struct: $STRUCT_NAME"
echo ""
echo "📝 Next steps:"
echo "1. Edit $MIGRATION_FILE"
echo "2. Replace the example SQL in up() with your schema changes"
echo "3. Add rollback SQL in down() (optional but recommended)"
echo "4. Run: make codegen"
echo "5. Test with: flutter run"
echo ""
echo "✨ The migration has been automatically registered in mod.rs"
echo ""
