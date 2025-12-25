/// Device management APIs
use anyhow::Result;

use super::helpers::*;
use crate::domain::ports::Repository;
use crate::infrastructure::database::DeviceEntity;

/// Get all devices as JSON array
pub fn get_all_devices() -> Result<String> {
    query_json(|| super::get_context().device_repo.get_all())
}

/// Get a device by ID as JSON object
pub fn get_device_by_id(id: i64) -> Result<String> {
    query_json(|| super::get_context().device_repo.get_by_id(id))
}

/// Get a device by remote ID as JSON object
pub fn get_device_by_remote_id(remote_id: String) -> Result<String> {
    query_json(|| {
        super::get_context()
            .device_repo
            .get_by_remote_id(&remote_id)
    })
}

/// Save a new device from JSON and return the assigned ID
pub fn save_device(device_json: String) -> Result<i64> {
    command_with_id(|| {
        let ctx = super::get_context();
        let mut device: DeviceEntity = serde_json::from_str(&device_json)?;
        let now = chrono::Utc::now().timestamp_millis();
        device.created_at = now;
        device.updated_at = now;
        device.id = None; // Ensure no ID for insert

        ctx.device_repo.insert(device)
    })
}

/// Update an existing device from JSON
pub fn update_device(id: i64, device_json: String) -> Result<()> {
    command(|| {
        let ctx = super::get_context();
        let mut device: DeviceEntity = serde_json::from_str(&device_json)?;
        device.updated_at = chrono::Utc::now().timestamp_millis();

        ctx.device_repo.update(id, device)
    })
}

/// Delete a device by ID
pub fn delete_device(id: i64) -> Result<()> {
    command(|| super::get_context().device_repo.delete(id))
}

/// Check if a device exists by remote ID
pub fn device_exists_by_remote_id(remote_id: String) -> Result<bool> {
    let ctx = super::get_context();
    let exists = ctx.device_repo.exists_by_remote_id(&remote_id)?;
    Ok(exists)
}
