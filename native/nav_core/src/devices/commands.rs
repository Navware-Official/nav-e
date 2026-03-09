// Device write operations.

#[derive(Debug, Clone)]
pub struct RegisterDeviceCommand {
    /// JSON-serialized DeviceEntity (id field is ignored on insert).
    pub device_json: String,
}

#[derive(Debug, Clone)]
pub struct UpdateDeviceCommand {
    pub id: i64,
    /// JSON-serialized DeviceEntity with updated fields.
    pub device_json: String,
}

#[derive(Debug, Clone)]
pub struct DeleteDeviceCommand {
    pub id: i64,
}
