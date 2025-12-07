/// SQLite database infrastructure for persistent storage
use anyhow::{Context, Result};
use rusqlite::{Connection, params};
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use crate::migrations::{MigrationManager, get_all_migrations};

#[flutter_rust_bridge::frb(ignore)]
pub struct Database {
    conn: Arc<Mutex<Connection>>,
}

impl Database {
    pub fn new(db_path: PathBuf) -> Result<Self> {
        let conn = Connection::open(db_path)
            .context("Failed to open database")?;
        
        let db = Self {
            conn: Arc::new(Mutex::new(conn)),
        };
        
        // Run migrations
        let manager = MigrationManager::new(db.get_connection());
        let migrations = get_all_migrations();
        manager.migrate(&migrations)
            .context("Failed to run database migrations")?;
        
        Ok(db)
    }

    pub fn get_connection(&self) -> Arc<Mutex<Connection>> {
        Arc::clone(&self.conn)
    }
}

// Saved Place entity
#[flutter_rust_bridge::frb(ignore)]
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SavedPlace {
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

// Device entity
#[flutter_rust_bridge::frb(ignore)]
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct Device {
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

// Saved Places Repository
#[flutter_rust_bridge::frb(ignore)]
pub struct SavedPlacesRepository {
    db: Arc<Mutex<Connection>>,
}

impl SavedPlacesRepository {
    pub fn new(db: Arc<Mutex<Connection>>) -> Self {
        Self { db }
    }

    pub fn get_all(&self) -> Result<Vec<SavedPlace>> {
        let conn = self.db.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, type_id, source, remote_id, name, address, lat, lon, created_at 
             FROM saved_places ORDER BY created_at DESC"
        )?;

        let places = stmt.query_map([], |row| {
            Ok(SavedPlace {
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
        })?
        .collect::<Result<Vec<_>, _>>()?;

        Ok(places)
    }

    pub fn get_by_id(&self, id: i64) -> Result<Option<SavedPlace>> {
        let conn = self.db.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, type_id, source, remote_id, name, address, lat, lon, created_at 
             FROM saved_places WHERE id = ?"
        )?;

        let result = stmt.query_row([id], |row| {
            Ok(SavedPlace {
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
        });

        match result {
            Ok(place) => Ok(Some(place)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    pub fn insert(&self, place: SavedPlace) -> Result<i64> {
        let conn = self.db.lock().unwrap();
        conn.execute(
            "INSERT INTO saved_places (type_id, source, remote_id, name, address, lat, lon, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            params![
                place.type_id,
                place.source,
                place.remote_id,
                place.name,
                place.address,
                place.lat,
                place.lon,
                place.created_at,
            ],
        )?;
        Ok(conn.last_insert_rowid())
    }

    pub fn delete(&self, id: i64) -> Result<()> {
        let conn = self.db.lock().unwrap();
        conn.execute("DELETE FROM saved_places WHERE id = ?", [id])?;
        Ok(())
    }
}

// Device Repository
#[flutter_rust_bridge::frb(ignore)]
pub struct DeviceRepository {
    db: Arc<Mutex<Connection>>,
}

impl DeviceRepository {
    pub fn new(db: Arc<Mutex<Connection>>) -> Self {
        Self { db }
    }

    pub fn get_all(&self) -> Result<Vec<Device>> {
        let conn = self.db.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, remote_id, name, device_type, connection_type, paired, 
                    last_connected, firmware_version, battery_level, created_at, updated_at 
             FROM devices ORDER BY name ASC"
        )?;

        let devices = stmt.query_map([], |row| {
            Ok(Device {
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
        })?
        .collect::<Result<Vec<_>, _>>()?;

        Ok(devices)
    }

    pub fn get_by_id(&self, id: i64) -> Result<Option<Device>> {
        let conn = self.db.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, remote_id, name, device_type, connection_type, paired, 
                    last_connected, firmware_version, battery_level, created_at, updated_at 
             FROM devices WHERE id = ?"
        )?;

        let result = stmt.query_row([id], |row| {
            Ok(Device {
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
        });

        match result {
            Ok(device) => Ok(Some(device)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    pub fn get_by_remote_id(&self, remote_id: &str) -> Result<Option<Device>> {
        let conn = self.db.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, remote_id, name, device_type, connection_type, paired, 
                    last_connected, firmware_version, battery_level, created_at, updated_at 
             FROM devices WHERE remote_id = ?"
        )?;

        let result = stmt.query_row([remote_id], |row| {
            Ok(Device {
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
        });

        match result {
            Ok(device) => Ok(Some(device)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    pub fn insert(&self, device: Device) -> Result<i64> {
        let conn = self.db.lock().unwrap();
        conn.execute(
            "INSERT INTO devices (remote_id, name, device_type, connection_type, paired, 
                                  last_connected, firmware_version, battery_level, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            params![
                device.remote_id,
                device.name,
                device.device_type,
                device.connection_type,
                if device.paired { 1 } else { 0 },
                device.last_connected,
                device.firmware_version,
                device.battery_level,
                device.created_at,
                device.updated_at,
            ],
        )?;
        Ok(conn.last_insert_rowid())
    }

    pub fn update(&self, id: i64, device: Device) -> Result<()> {
        let conn = self.db.lock().unwrap();
        conn.execute(
            "UPDATE devices 
             SET remote_id = ?, name = ?, device_type = ?, connection_type = ?, paired = ?, 
                 last_connected = ?, firmware_version = ?, battery_level = ?, updated_at = ?
             WHERE id = ?",
            params![
                device.remote_id,
                device.name,
                device.device_type,
                device.connection_type,
                if device.paired { 1 } else { 0 },
                device.last_connected,
                device.firmware_version,
                device.battery_level,
                device.updated_at,
                id,
            ],
        )?;
        Ok(())
    }

    pub fn delete(&self, id: i64) -> Result<()> {
        let conn = self.db.lock().unwrap();
        conn.execute("DELETE FROM devices WHERE id = ?", [id])?;
        Ok(())
    }

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
