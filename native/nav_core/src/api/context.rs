//! API context bridge — re-exports from the app container.
//!
//! The composition root lives in `crate::app::container`. This module exists
//! so that existing `pub use context::*` in `api/mod.rs` continues to expose
//! `initialize_database` and `subscribe_navigation_events`.

pub use crate::app::container::{
    initialize_database, subscribe_device_messages, subscribe_navigation_events,
};
