/// Device management APIs
use anyhow::Result;

use crate::api::helpers::*;
use crate::app::container::get_container;
use crate::devices::commands::*;
use crate::devices::queries::*;

/// Get all devices as JSON array
pub fn get_all_devices() -> Result<String> {
    query_json(|| get_container().devices.get_all_devices(GetAllDevicesQuery))
}

/// Get a device by ID as JSON object
pub fn get_device_by_id(id: i64) -> Result<String> {
    query_json(|| get_container().devices.get_device_by_id(GetDeviceByIdQuery { id }))
}

/// Get a device by remote ID as JSON object
pub fn get_device_by_remote_id(remote_id: String) -> Result<String> {
    query_json(|| {
        get_container()
            .devices
            .get_device_by_remote_id(GetDeviceByRemoteIdQuery { remote_id })
    })
}

/// Save a new device from JSON and return the assigned ID
pub fn save_device(device_json: String) -> Result<i64> {
    get_container().devices.register_device(RegisterDeviceCommand { device_json })
}

/// Update an existing device from JSON
pub fn update_device(id: i64, device_json: String) -> Result<()> {
    get_container().devices.update_device(UpdateDeviceCommand { id, device_json })
}

/// Delete a device by ID
pub fn delete_device(id: i64) -> Result<()> {
    get_container().devices.delete_device(DeleteDeviceCommand { id })
}

/// Check if a device exists by remote ID
pub fn device_exists_by_remote_id(remote_id: String) -> Result<bool> {
    get_container()
        .devices
        .device_exists_by_remote_id(DeviceExistsByRemoteIdQuery { remote_id })
}
