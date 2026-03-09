#![allow(hidden_glob_reexports)]
pub(crate) mod infrastructure; // Internal - adapters
pub(crate) mod shared; // Internal - shared value objects

// Vertical bounded-context modules
pub(crate) mod devices; // Devices bounded context
pub(crate) mod navigation; // Navigation domain + application + infrastructure
pub(crate) mod offline;
pub(crate) mod places; // Places/trips/routes bounded context // Offline regions bounded context

// Composition root
pub(crate) mod app;

// Private module - database migrations (not exposed via FFI)
#[cfg_attr(not(target_family = "wasm"), path = "migrations/mod.rs")]
mod migrations;

// Modern API layer - organized by feature
pub mod api;

// Re-export all public APIs from feature modules
pub use api::*;

// Port traits and value types — exposed so nav_route can implement them
pub use navigation::domain::events::NavigationEvent;
pub use navigation::domain::ports::{GeocodingService, RouteService};
pub use shared::value_objects::{GeocodingSearchResult, Position};
