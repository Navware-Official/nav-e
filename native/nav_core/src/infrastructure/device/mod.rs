// Device communication adapters: protobuf transport (message building lives in device_comm).
pub mod no_op_device_comm;
pub mod protobuf_adapter;

pub use no_op_device_comm::*;
pub use protobuf_adapter::*;
