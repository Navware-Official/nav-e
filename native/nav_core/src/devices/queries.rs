// Device read operations.

#[derive(Debug, Clone)]
pub struct GetAllDevicesQuery;

#[derive(Debug, Clone)]
pub struct GetDeviceByIdQuery {
    pub id: i64,
}

#[derive(Debug, Clone)]
pub struct GetDeviceByRemoteIdQuery {
    pub remote_id: String,
}

#[derive(Debug, Clone)]
pub struct DeviceExistsByRemoteIdQuery {
    pub remote_id: String,
}
