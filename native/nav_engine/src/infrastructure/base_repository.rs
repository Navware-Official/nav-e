/// Base repository implementation for common CRUD operations
///
/// This module provides a generic base repository that handles standard
/// database operations, reducing boilerplate in concrete repositories.
use anyhow::{Context, Result};
use rusqlite::{Connection, Row};
use std::marker::PhantomData;
use std::sync::{Arc, Mutex};

use crate::domain::ports::Repository;

/// Trait for entities that can be persisted to database
///
/// Implement this trait to define how your entity maps to/from database rows.
pub trait DatabaseEntity: Sized + Send + Sync {
    /// The ID type for this entity (typically i64)
    type Id;

    /// The database table name
    fn table_name() -> &'static str;

    /// Convert a database row to an entity instance
    fn from_row(row: &Row) -> rusqlite::Result<Self>;

    /// Get column names for SELECT queries (comma-separated)
    fn column_names() -> &'static str;

    /// Get column names for INSERT (excluding id)
    fn insert_columns() -> &'static str;

    /// Get placeholders for INSERT (?, ?, ...)
    fn insert_placeholders() -> &'static str;

    /// Bind entity values to INSERT statement (excluding id)
    fn bind_insert(&self, stmt: &mut rusqlite::Statement, start_idx: usize)
        -> rusqlite::Result<()>;

    /// Bind entity values to UPDATE statement (excluding id)
    fn bind_update(&self, stmt: &mut rusqlite::Statement, start_idx: usize)
        -> rusqlite::Result<()>;
}

/// Generic base repository implementation
///
/// Provides standard CRUD operations for any entity implementing DatabaseEntity.
///
/// # Example
/// ```rust
/// let repo = BaseRepository::<SavedPlace, i64>::new(db_conn);
/// let places = repo.get_all()?;
/// ```
#[derive(Clone)]
pub struct BaseRepository<T, ID> {
    db: Arc<Mutex<Connection>>,
    _phantom: PhantomData<(T, ID)>,
}

impl<T, ID> BaseRepository<T, ID>
where
    T: DatabaseEntity<Id = ID>,
    ID: Copy + Send + Sync,
{
    /// Create a new base repository instance
    pub fn new(db: Arc<Mutex<Connection>>) -> Self {
        Self {
            db,
            _phantom: PhantomData,
        }
    }

    /// Get reference to database connection
    pub fn db(&self) -> &Arc<Mutex<Connection>> {
        &self.db
    }
}

impl<T, ID> Repository<T, ID> for BaseRepository<T, ID>
where
    T: DatabaseEntity<Id = ID>,
    ID: Copy + Send + Sync + rusqlite::types::FromSql + rusqlite::ToSql,
{
    fn get_all(&self) -> Result<Vec<T>> {
        let conn = self.db.lock().unwrap();
        let sql = format!(
            "SELECT {} FROM {} ORDER BY created_at DESC",
            T::column_names(),
            T::table_name()
        );

        let mut stmt = conn
            .prepare(&sql)
            .context("Failed to prepare get_all query")?;

        let entities = stmt
            .query_map([], T::from_row)?
            .collect::<rusqlite::Result<Vec<_>>>()
            .context("Failed to map rows to entities")?;

        Ok(entities)
    }

    fn get_by_id(&self, id: ID) -> Result<Option<T>> {
        let conn = self.db.lock().unwrap();
        let sql = format!(
            "SELECT {} FROM {} WHERE id = ?",
            T::column_names(),
            T::table_name()
        );

        let mut stmt = conn
            .prepare(&sql)
            .context("Failed to prepare get_by_id query")?;

        let result = stmt.query_row([id], T::from_row);

        match result {
            Ok(entity) => Ok(Some(entity)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    fn insert(&self, entity: T) -> Result<ID> {
        let conn = self.db.lock().unwrap();
        let sql = format!(
            "INSERT INTO {} ({}) VALUES ({})",
            T::table_name(),
            T::insert_columns(),
            T::insert_placeholders()
        );

        let mut stmt = conn
            .prepare(&sql)
            .context("Failed to prepare insert query")?;

        entity.bind_insert(&mut stmt, 1)?;
        stmt.raw_execute().context("Failed to execute insert")?;

        let id = conn.last_insert_rowid();

        // Convert i64 to ID type - this assumes ID implements From<i64>
        // For i64, this is a no-op. For other types, implement From trait.
        Ok(unsafe { std::mem::transmute_copy(&id) })
    }

    fn update(&self, id: ID, entity: T) -> Result<()> {
        let conn = self.db.lock().unwrap();

        // Build UPDATE SET clause dynamically based on insert columns
        let columns: Vec<&str> = T::insert_columns().split(", ").collect();
        let set_clause = columns
            .iter()
            .map(|col| format!("{} = ?", col))
            .collect::<Vec<_>>()
            .join(", ");

        let sql = format!("UPDATE {} SET {} WHERE id = ?", T::table_name(), set_clause);

        let mut stmt = conn
            .prepare(&sql)
            .context("Failed to prepare update query")?;

        entity.bind_update(&mut stmt, 1)?;

        // Bind the ID at the end (after all entity fields)
        let param_count = columns.len();
        stmt.raw_bind_parameter(param_count + 1, id)?;

        stmt.raw_execute().context("Failed to execute update")?;

        Ok(())
    }

    fn delete(&self, id: ID) -> Result<()> {
        let conn = self.db.lock().unwrap();
        let sql = format!("DELETE FROM {} WHERE id = ?", T::table_name());

        conn.execute(&sql, [id])
            .context("Failed to delete entity")?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rusqlite::Connection;

    // Test entity
    #[derive(Debug, Clone, PartialEq)]
    struct TestEntity {
        id: Option<i64>,
        name: String,
        value: i32,
        created_at: i64,
    }

    impl DatabaseEntity for TestEntity {
        type Id = i64;

        fn table_name() -> &'static str {
            "test_entities"
        }

        fn from_row(row: &Row) -> rusqlite::Result<Self> {
            Ok(TestEntity {
                id: Some(row.get(0)?),
                name: row.get(1)?,
                value: row.get(2)?,
                created_at: row.get(3)?,
            })
        }

        fn column_names() -> &'static str {
            "id, name, value, created_at"
        }

        fn insert_columns() -> &'static str {
            "name, value, created_at"
        }

        fn insert_placeholders() -> &'static str {
            "?, ?, ?"
        }

        fn bind_insert(
            &self,
            stmt: &mut rusqlite::Statement,
            start_idx: usize,
        ) -> rusqlite::Result<()> {
            stmt.raw_bind_parameter(start_idx, &self.name)?;
            stmt.raw_bind_parameter(start_idx + 1, self.value)?;
            stmt.raw_bind_parameter(start_idx + 2, self.created_at)?;
            Ok(())
        }

        fn bind_update(
            &self,
            stmt: &mut rusqlite::Statement,
            start_idx: usize,
        ) -> rusqlite::Result<()> {
            self.bind_insert(stmt, start_idx)
        }
    }

    fn setup_test_db() -> Arc<Mutex<Connection>> {
        let conn = Connection::open_in_memory().unwrap();
        conn.execute(
            "CREATE TABLE test_entities (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                value INTEGER NOT NULL,
                created_at INTEGER NOT NULL
            )",
            [],
        )
        .unwrap();
        Arc::new(Mutex::new(conn))
    }

    #[test]
    fn test_insert_and_get_by_id() {
        let db = setup_test_db();
        let repo = BaseRepository::<TestEntity, i64>::new(db);

        let entity = TestEntity {
            id: None,
            name: "Test".to_string(),
            value: 42,
            created_at: 1234567890,
        };

        let id = repo.insert(entity.clone()).unwrap();
        assert_eq!(id, 1);

        let retrieved = repo.get_by_id(id).unwrap();
        assert!(retrieved.is_some());
        let retrieved = retrieved.unwrap();
        assert_eq!(retrieved.name, "Test");
        assert_eq!(retrieved.value, 42);
    }

    #[test]
    fn test_get_all() {
        let db = setup_test_db();
        let repo = BaseRepository::<TestEntity, i64>::new(db);

        let entity1 = TestEntity {
            id: None,
            name: "First".to_string(),
            value: 1,
            created_at: 1000,
        };
        let entity2 = TestEntity {
            id: None,
            name: "Second".to_string(),
            value: 2,
            created_at: 2000,
        };

        repo.insert(entity1).unwrap();
        repo.insert(entity2).unwrap();

        let all = repo.get_all().unwrap();
        assert_eq!(all.len(), 2);
    }

    #[test]
    fn test_update() {
        let db = setup_test_db();
        let repo = BaseRepository::<TestEntity, i64>::new(db);

        let entity = TestEntity {
            id: None,
            name: "Original".to_string(),
            value: 10,
            created_at: 1000,
        };

        let id = repo.insert(entity).unwrap();

        let updated = TestEntity {
            id: Some(id),
            name: "Updated".to_string(),
            value: 20,
            created_at: 1000,
        };

        repo.update(id, updated).unwrap();

        let retrieved = repo.get_by_id(id).unwrap().unwrap();
        assert_eq!(retrieved.name, "Updated");
        assert_eq!(retrieved.value, 20);
    }

    #[test]
    fn test_delete() {
        let db = setup_test_db();
        let repo = BaseRepository::<TestEntity, i64>::new(db);

        let entity = TestEntity {
            id: None,
            name: "ToDelete".to_string(),
            value: 99,
            created_at: 1000,
        };

        let id = repo.insert(entity).unwrap();
        assert!(repo.get_by_id(id).unwrap().is_some());

        repo.delete(id).unwrap();
        assert!(repo.get_by_id(id).unwrap().is_none());
    }
}
