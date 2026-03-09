// Device application service — handles all device management use cases.
use anyhow::Result;
use chrono::Utc;

use crate::devices::commands::*;
use crate::devices::queries::*;
use crate::infrastructure::database::{DeviceEntity, DeviceRepository};
use crate::navigation::domain::ports::Repository;

/// Handles all use cases for device registration and lookup.
///
/// Constructed once in [`AppContext`] and held for the lifetime of the app.
pub struct DevicesHandlers {
    device_repo: DeviceRepository,
}

impl DevicesHandlers {
    pub fn new(device_repo: DeviceRepository) -> Self {
        Self { device_repo }
    }

    pub fn get_all_devices(&self, _: GetAllDevicesQuery) -> Result<Vec<DeviceEntity>> {
        self.device_repo.get_all()
    }

    pub fn get_device_by_id(&self, q: GetDeviceByIdQuery) -> Result<Option<DeviceEntity>> {
        self.device_repo.get_by_id(q.id)
    }

    pub fn get_device_by_remote_id(
        &self,
        q: GetDeviceByRemoteIdQuery,
    ) -> Result<Option<DeviceEntity>> {
        self.device_repo.get_by_remote_id(&q.remote_id)
    }

    pub fn device_exists_by_remote_id(&self, q: DeviceExistsByRemoteIdQuery) -> Result<bool> {
        self.device_repo.exists_by_remote_id(&q.remote_id)
    }

    pub fn register_device(&self, cmd: RegisterDeviceCommand) -> Result<i64> {
        let mut device: DeviceEntity = serde_json::from_str(&cmd.device_json)
            .map_err(|e| anyhow::anyhow!("Invalid device JSON: {}", e))?;
        let now = Utc::now().timestamp_millis();
        device.id = None; // ensure clean insert
        device.created_at = now;
        device.updated_at = now;
        self.device_repo.insert(device)
    }

    pub fn update_device(&self, cmd: UpdateDeviceCommand) -> Result<()> {
        let mut device: DeviceEntity = serde_json::from_str(&cmd.device_json)
            .map_err(|e| anyhow::anyhow!("Invalid device JSON: {}", e))?;
        device.updated_at = Utc::now().timestamp_millis();
        self.device_repo.update(cmd.id, device)
    }

    pub fn delete_device(&self, cmd: DeleteDeviceCommand) -> Result<()> {
        self.device_repo.delete(cmd.id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::migrations::{get_all_migrations, MigrationManager};
    use rusqlite::Connection;
    use std::sync::{Arc, Mutex};

    fn setup_db() -> Arc<Mutex<Connection>> {
        let conn = Arc::new(Mutex::new(Connection::open_in_memory().unwrap()));
        MigrationManager::new(Arc::clone(&conn))
            .migrate(&get_all_migrations())
            .unwrap();
        conn
    }

    fn handlers(db: Arc<Mutex<Connection>>) -> DevicesHandlers {
        DevicesHandlers::new(DeviceRepository::new(db))
    }

    fn device_json(remote_id: &str) -> String {
        let now = Utc::now().timestamp_millis();
        serde_json::json!({
            "id": null,
            "remote_id": remote_id,
            "name": "Test Watch",
            "device_type": "WearOs",
            "connection_type": "BLE",
            "paired": true,
            "last_connected": null,
            "firmware_version": null,
            "battery_level": null,
            "created_at": now,
            "updated_at": now,
        })
        .to_string()
    }

    #[test]
    fn register_and_get_device() {
        let h = handlers(setup_db());
        let id = h
            .register_device(RegisterDeviceCommand {
                device_json: device_json("AA:BB:CC"),
            })
            .unwrap();
        let device = h
            .get_device_by_id(GetDeviceByIdQuery { id })
            .unwrap()
            .unwrap();
        assert_eq!(device.remote_id, "AA:BB:CC");
        assert_eq!(device.name, "Test Watch");
    }

    #[test]
    fn get_all_devices_returns_all() {
        let h = handlers(setup_db());
        h.register_device(RegisterDeviceCommand {
            device_json: device_json("D1"),
        })
        .unwrap();
        h.register_device(RegisterDeviceCommand {
            device_json: device_json("D2"),
        })
        .unwrap();
        assert_eq!(h.get_all_devices(GetAllDevicesQuery).unwrap().len(), 2);
    }

    #[test]
    fn get_device_by_remote_id_found() {
        let h = handlers(setup_db());
        h.register_device(RegisterDeviceCommand {
            device_json: device_json("REM-1"),
        })
        .unwrap();
        let found = h
            .get_device_by_remote_id(GetDeviceByRemoteIdQuery {
                remote_id: "REM-1".into(),
            })
            .unwrap();
        assert!(found.is_some());
        assert_eq!(found.unwrap().remote_id, "REM-1");
    }

    #[test]
    fn get_device_by_remote_id_not_found() {
        let h = handlers(setup_db());
        assert!(h
            .get_device_by_remote_id(GetDeviceByRemoteIdQuery {
                remote_id: "NOPE".into()
            })
            .unwrap()
            .is_none());
    }

    #[test]
    fn device_exists_by_remote_id() {
        let h = handlers(setup_db());
        assert!(!h
            .device_exists_by_remote_id(DeviceExistsByRemoteIdQuery {
                remote_id: "X".into()
            })
            .unwrap());
        h.register_device(RegisterDeviceCommand {
            device_json: device_json("X"),
        })
        .unwrap();
        assert!(h
            .device_exists_by_remote_id(DeviceExistsByRemoteIdQuery {
                remote_id: "X".into()
            })
            .unwrap());
    }

    #[test]
    fn update_device_changes_fields() {
        let h = handlers(setup_db());
        let id = h
            .register_device(RegisterDeviceCommand {
                device_json: device_json("UPD-1"),
            })
            .unwrap();
        let mut updated: DeviceEntity = serde_json::from_str(&device_json("UPD-1")).unwrap();
        updated.name = "Updated Watch".into();
        updated.battery_level = Some(80);
        h.update_device(UpdateDeviceCommand {
            id,
            device_json: serde_json::to_string(&updated).unwrap(),
        })
        .unwrap();
        let device = h
            .get_device_by_id(GetDeviceByIdQuery { id })
            .unwrap()
            .unwrap();
        assert_eq!(device.name, "Updated Watch");
        assert_eq!(device.battery_level, Some(80));
    }

    #[test]
    fn delete_device_removes_it() {
        let h = handlers(setup_db());
        let id = h
            .register_device(RegisterDeviceCommand {
                device_json: device_json("DEL-1"),
            })
            .unwrap();
        h.delete_device(DeleteDeviceCommand { id }).unwrap();
        assert!(h
            .get_device_by_id(GetDeviceByIdQuery { id })
            .unwrap()
            .is_none());
    }

    #[test]
    fn register_device_rejects_invalid_json() {
        let h = handlers(setup_db());
        let result = h.register_device(RegisterDeviceCommand {
            device_json: "not json".into(),
        });
        assert!(result.is_err());
    }
}
