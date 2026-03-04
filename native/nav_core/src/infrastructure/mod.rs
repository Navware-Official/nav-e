// Infrastructure Layer - Adapters grouped by type (Hexagonal Architecture)
//
// persistence/  - database, base repository, in-memory store
// routing/      - OSRM adapter
// geocoding/    - Nominatim/Photon adapter
// device/       - Nav-IR to proto, protobuf device communication

pub mod device;
pub mod geocoding;
pub mod persistence;
pub mod routing;

// Re-export so crate::infrastructure::Database, nav_ir_route_to_route_blob, etc. work
pub use device::*;
pub use geocoding::*;
pub use persistence::*;
pub use routing::*;

// Keep database as a submodule path for api code that uses crate::infrastructure::database::*
pub use persistence::database;
