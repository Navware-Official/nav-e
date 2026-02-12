use crate::domain::ports::Repository;
use crate::infrastructure::base_repository::{BaseRepository, DatabaseEntity};
use crate::migrations::{get_all_migrations, MigrationManager};
/// SQLite database infrastructure for persistent storage
use anyhow::{Context, Result};
use rusqlite::{Connection, Row};
use std::path::PathBuf;
use std::sync::{Arc, Mutex};

pub struct Database {
    conn: Arc<Mutex<Connection>>,
}

impl Database {
    pub fn new(db_path: PathBuf) -> Result<Self> {
        // Simply try to open the database - the parent directory should already exist on Android
        // Android automatically creates /data/data/<package>/files/ for apps
        let conn = Connection::open(&db_path)
            .with_context(|| format!("Unable to open database file: {}", db_path.display()))?;

        let db = Self {
            conn: Arc::new(Mutex::new(conn)),
        };

        // Run migrations
        let manager = MigrationManager::new(db.get_connection());
        let migrations = get_all_migrations();
        manager
            .migrate(&migrations)
            .context("Failed to run database migrations")?;

        Ok(db)
    }

    pub fn get_connection(&self) -> Arc<Mutex<Connection>> {
        Arc::clone(&self.conn)
    }
}

// Saved Place entity (database representation)
// This is separate from any domain entity and is used only for persistence
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SavedPlaceEntity {
    pub id: Option<i64>,
    pub type_id: Option<i64>,
    pub source: String,
    pub remote_id: Option<String>,
    pub name: String,
    pub address: Option<String>,
    pub lat: f64,
    pub lon: f64,
    pub created_at: i64,
}

impl DatabaseEntity for SavedPlaceEntity {
    type Id = i64;

    fn table_name() -> &'static str {
        "saved_places"
    }

    fn from_row(row: &Row) -> rusqlite::Result<Self> {
        Ok(SavedPlaceEntity {
            id: Some(row.get(0)?),
            type_id: row.get(1)?,
            source: row.get(2)?,
            remote_id: row.get(3)?,
            name: row.get(4)?,
            address: row.get(5)?,
            lat: row.get(6)?,
            lon: row.get(7)?,
            created_at: row.get(8)?,
        })
    }

    fn column_names() -> &'static str {
        "id, type_id, source, remote_id, name, address, lat, lon, created_at"
    }

    fn insert_columns() -> &'static str {
        "type_id, source, remote_id, name, address, lat, lon, created_at"
    }

    fn insert_placeholders() -> &'static str {
        "?, ?, ?, ?, ?, ?, ?, ?"
    }

    fn bind_insert(
        &self,
        stmt: &mut rusqlite::Statement,
        start_idx: usize,
    ) -> rusqlite::Result<()> {
        stmt.raw_bind_parameter(start_idx, self.type_id)?;
        stmt.raw_bind_parameter(start_idx + 1, &self.source)?;
        stmt.raw_bind_parameter(start_idx + 2, self.remote_id.as_ref())?;
        stmt.raw_bind_parameter(start_idx + 3, &self.name)?;
        stmt.raw_bind_parameter(start_idx + 4, self.address.as_ref())?;
        stmt.raw_bind_parameter(start_idx + 5, self.lat)?;
        stmt.raw_bind_parameter(start_idx + 6, self.lon)?;
        stmt.raw_bind_parameter(start_idx + 7, self.created_at)?;
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

// Device entity (database representation)
// This is separate from the domain Device entity and is used only for persistence
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct DeviceEntity {
    pub id: Option<i64>,
    pub remote_id: String,
    pub name: String,
    pub device_type: String,
    pub connection_type: String,
    pub paired: bool,
    pub last_connected: Option<i64>,
    pub firmware_version: Option<String>,
    pub battery_level: Option<i32>,
    pub created_at: i64,
    pub updated_at: i64,
}

impl DatabaseEntity for DeviceEntity {
    type Id = i64;

    fn table_name() -> &'static str {
        "devices"
    }

    fn from_row(row: &Row) -> rusqlite::Result<Self> {
        Ok(DeviceEntity {
            id: Some(row.get(0)?),
            remote_id: row.get(1)?,
            name: row.get(2)?,
            device_type: row.get(3)?,
            connection_type: row.get(4)?,
            paired: row.get::<_, i32>(5)? != 0,
            last_connected: row.get(6)?,
            firmware_version: row.get(7)?,
            battery_level: row.get(8)?,
            created_at: row.get(9)?,
            updated_at: row.get(10)?,
        })
    }

    fn column_names() -> &'static str {
        "id, remote_id, name, device_type, connection_type, paired, last_connected, firmware_version, battery_level, created_at, updated_at"
    }

    fn insert_columns() -> &'static str {
        "remote_id, name, device_type, connection_type, paired, last_connected, firmware_version, battery_level, created_at, updated_at"
    }

    fn insert_placeholders() -> &'static str {
        "?, ?, ?, ?, ?, ?, ?, ?, ?, ?"
    }

    fn bind_insert(
        &self,
        stmt: &mut rusqlite::Statement,
        start_idx: usize,
    ) -> rusqlite::Result<()> {
        stmt.raw_bind_parameter(start_idx, &self.remote_id)?;
        stmt.raw_bind_parameter(start_idx + 1, &self.name)?;
        stmt.raw_bind_parameter(start_idx + 2, &self.device_type)?;
        stmt.raw_bind_parameter(start_idx + 3, &self.connection_type)?;
        stmt.raw_bind_parameter(start_idx + 4, if self.paired { 1 } else { 0 })?;
        stmt.raw_bind_parameter(start_idx + 5, self.last_connected)?;
        stmt.raw_bind_parameter(start_idx + 6, self.firmware_version.as_ref())?;
        stmt.raw_bind_parameter(start_idx + 7, self.battery_level)?;
        stmt.raw_bind_parameter(start_idx + 8, self.created_at)?;
        stmt.raw_bind_parameter(start_idx + 9, self.updated_at)?;
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

// Saved Places Repository
#[derive(Clone)]
pub struct SavedPlacesRepository {
    base: BaseRepository<SavedPlaceEntity, i64>,
}

impl SavedPlacesRepository {
    pub fn new(db: Arc<Mutex<Connection>>) -> Self {
        Self {
            base: BaseRepository::new(db),
        }
    }
}

// Delegate to base repository implementation
impl Repository<SavedPlaceEntity, i64> for SavedPlacesRepository {
    fn get_all(&self) -> Result<Vec<SavedPlaceEntity>> {
        self.base.get_all()
    }

    fn get_by_id(&self, id: i64) -> Result<Option<SavedPlaceEntity>> {
        self.base.get_by_id(id)
    }

    fn insert(&self, entity: SavedPlaceEntity) -> Result<i64> {
        self.base.insert(entity)
    }

    fn update(&self, id: i64, entity: SavedPlaceEntity) -> Result<()> {
        self.base.update(id, entity)
    }

    fn delete(&self, id: i64) -> Result<()> {
        self.base.delete(id)
    }
}

// Device Repository
#[derive(Clone)]
pub struct DeviceRepository {
    base: BaseRepository<DeviceEntity, i64>,
    db: Arc<Mutex<Connection>>, // Keep for specialized methods
}

impl DeviceRepository {
    pub fn new(db: Arc<Mutex<Connection>>) -> Self {
        Self {
            base: BaseRepository::new(db.clone()),
            db,
        }
    }

    // Specialized method: query by remote_id
    pub fn get_by_remote_id(&self, remote_id: &str) -> Result<Option<DeviceEntity>> {
        let conn = self.db.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, remote_id, name, device_type, connection_type, paired, 
                    last_connected, firmware_version, battery_level, created_at, updated_at 
             FROM devices WHERE remote_id = ?",
        )?;

        let result = stmt.query_row([remote_id], DeviceEntity::from_row);

        match result {
            Ok(device) => Ok(Some(device)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    // Specialized method: check existence by remote_id
    pub fn exists_by_remote_id(&self, remote_id: &str) -> Result<bool> {
        let conn = self.db.lock().unwrap();
        let count: i64 = conn.query_row(
            "SELECT COUNT(*) FROM devices WHERE remote_id = ?",
            [remote_id],
            |row| row.get(0),
        )?;
        Ok(count > 0)
    }
}

// Delegate to base repository implementation
impl Repository<DeviceEntity, i64> for DeviceRepository {
    fn get_all(&self) -> Result<Vec<DeviceEntity>> {
        self.base.get_all()
    }

    fn get_by_id(&self, id: i64) -> Result<Option<DeviceEntity>> {
        self.base.get_by_id(id)
    }

    fn insert(&self, entity: DeviceEntity) -> Result<i64> {
        self.base.insert(entity)
    }

    fn update(&self, id: i64, entity: DeviceEntity) -> Result<()> {
        self.base.update(id, entity)
    }

    fn delete(&self, id: i64) -> Result<()> {
        self.base.delete(id)
    }
}

// ============================================================================
// Offline region entity and repository (String id, custom impl)
// ============================================================================

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OfflineRegionEntity {
    pub id: String,
    pub name: String,
    pub north: f64,
    pub south: f64,
    pub east: f64,
    pub west: f64,
    pub min_zoom: i32,
    pub max_zoom: i32,
    pub relative_path: String,
    pub size_bytes: i64,
    pub created_at: i64,
}

#[derive(Clone)]
pub struct OfflineRegionsRepository {
    db: Arc<Mutex<Connection>>,
    storage_base_path: std::path::PathBuf,
}

impl OfflineRegionsRepository {
    pub fn new(db: Arc<Mutex<Connection>>, storage_base_path: std::path::PathBuf) -> Self {
        Self {
            db,
            storage_base_path,
        }
    }

    pub fn get_all(&self) -> Result<Vec<OfflineRegionEntity>> {
        let conn = self.db.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, name, north, south, east, west, min_zoom, max_zoom, relative_path, size_bytes, created_at
             FROM offline_regions ORDER BY created_at DESC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(OfflineRegionEntity {
                id: row.get(0)?,
                name: row.get(1)?,
                north: row.get(2)?,
                south: row.get(3)?,
                east: row.get(4)?,
                west: row.get(5)?,
                min_zoom: row.get(6)?,
                max_zoom: row.get(7)?,
                relative_path: row.get(8)?,
                size_bytes: row.get(9)?,
                created_at: row.get(10)?,
            })
        })?;
        rows.collect::<rusqlite::Result<Vec<_>>>()
            .map_err(Into::into)
    }

    pub fn get_by_id(&self, id: &str) -> Result<Option<OfflineRegionEntity>> {
        let conn = self.db.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, name, north, south, east, west, min_zoom, max_zoom, relative_path, size_bytes, created_at
             FROM offline_regions WHERE id = ?",
        )?;
        let result = stmt.query_row([id], |row| {
            Ok(OfflineRegionEntity {
                id: row.get(0)?,
                name: row.get(1)?,
                north: row.get(2)?,
                south: row.get(3)?,
                east: row.get(4)?,
                west: row.get(5)?,
                min_zoom: row.get(6)?,
                max_zoom: row.get(7)?,
                relative_path: row.get(8)?,
                size_bytes: row.get(9)?,
                created_at: row.get(10)?,
            })
        });
        match result {
            Ok(e) => Ok(Some(e)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    pub fn insert(&self, entity: &OfflineRegionEntity) -> Result<()> {
        let conn = self.db.lock().unwrap();
        conn.execute(
            "INSERT INTO offline_regions (id, name, north, south, east, west, min_zoom, max_zoom, relative_path, size_bytes, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)",
            rusqlite::params![
                entity.id,
                entity.name,
                entity.north,
                entity.south,
                entity.east,
                entity.west,
                entity.min_zoom,
                entity.max_zoom,
                entity.relative_path,
                entity.size_bytes,
                entity.created_at,
            ],
        )?;
        Ok(())
    }

    pub fn delete(&self, id: &str) -> Result<()> {
        let conn = self.db.lock().unwrap();
        conn.execute("DELETE FROM offline_regions WHERE id = ?", [id])?;
        Ok(())
    }

    pub fn get_region_for_viewport(
        &self,
        north: f64,
        south: f64,
        east: f64,
        west: f64,
    ) -> Result<Option<OfflineRegionEntity>> {
        let regions = self.get_all()?;
        for r in regions {
            if r.intersects_bbox(north, south, east, west) {
                return Ok(Some(r));
            }
        }
        Ok(None)
    }

    pub fn get_storage_path(&self) -> Result<String> {
        Ok(self.storage_base_path.to_string_lossy().into_owned())
    }
}

impl OfflineRegionEntity {
    pub fn intersects_bbox(&self, n: f64, s: f64, e: f64, w: f64) -> bool {
        !(n < self.south || s > self.north || e < self.west || w > self.east)
    }
}
