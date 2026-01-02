pub(crate) mod application; // Internal - CQRS layer
pub(crate) mod domain; // Internal - domain layer
pub(crate) mod infrastructure; // Internal - adapters

// Private module - database migrations (not exposed via FFI)
#[cfg_attr(not(target_family = "wasm"), path = "migrations/mod.rs")]
mod migrations;

// Modern API layer - organized by feature
pub mod api;

// Re-export all public APIs from feature modules
pub use api::*;
