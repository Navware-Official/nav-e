// Domain Layer - Pure business logic, no external dependencies
pub mod entities;
pub(crate) mod events;
pub mod ports;
pub mod value_objects; // Internal - not exposed to FFI
