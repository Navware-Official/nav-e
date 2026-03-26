//! Normalization adapters: external formats → Nav-IR Route.
//!
//! nav_ir becomes the bridge between external ecosystems (OSRM, GPX, custom APIs)
//! and the rest of the system; Flutter and device_comm stop caring where the route came from.

mod custom_api;
mod gpx;
mod google_routes;
mod graphhopper;
mod osrm;
mod valhalla;

pub use custom_api::normalize_custom;
pub use gpx::normalize_gpx;
pub use google_routes::normalize_google_routes;
pub use graphhopper::normalize_graphhopper;
pub use osrm::{normalize_osrm, OsrmResponse};
pub use valhalla::normalize_valhalla;
