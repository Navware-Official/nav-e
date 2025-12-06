// Domain Layer - Pure business logic, no external dependencies
pub mod entities;
pub mod value_objects;
pub mod ports;
pub(crate) mod events;  // Internal - not exposed to FFI
