// Infrastructure Layer - Adapters grouped by type (Hexagonal Architecture)
//
// persistence/  - database, base repository, SQLite + in-memory navigation repos
// device/       - Nav-IR to proto, protobuf device communication
//
// routing/ and geocoding/ implementations now live in nav_route.

pub mod device;
pub mod geocoding;
pub mod persistence;
pub mod routing;

// Re-export so crate::infrastructure::Database, NoOpDeviceComm, etc. work
pub use device::*;
pub use persistence::*;

// Keep database as a submodule path for api code that uses crate::infrastructure::database::*
pub use persistence::database;
