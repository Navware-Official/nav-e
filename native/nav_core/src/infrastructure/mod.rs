// Infrastructure Layer - Adapters grouped by type (Hexagonal Architecture)
//
// persistence/  - database, base repository, in-memory navigation repo
// device/       - Nav-IR to proto, protobuf device communication
//
// routing/ and geocoding/ implementations now live in nav_route.

pub mod device;
pub mod geocoding;
pub mod persistence;
pub mod routing;

// Keep database as a submodule path for api code that uses crate::infrastructure::database::*
pub use persistence::database;
