//! `nav_engine` — runtime turn-by-turn navigation engine.
//!
//! Pure logic crate: no I/O, no async, no FFI. Depends only on `nav_ir`.
//! Feed a `nav_ir::Route` and GPS position updates to get structured `NavigationState` snapshots.

pub mod derive_instructions;
pub mod engine;
pub mod off_route;
pub mod progress;
pub mod types;

pub use engine::NavigationEngine;
pub use types::*;
