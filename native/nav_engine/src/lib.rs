mod frb_generated;

pub mod domain;
pub(crate) mod application;  // Internal - CQRS layer
pub(crate) mod infrastructure;  // Internal - adapters

// Private module - database migrations (not exposed via FFI)
mod migrations;

// Re-export commonly used types for frb_generated.rs (internal use only)
pub(crate) use std::sync::Mutex;
pub(crate) use domain::ports::{
    DeviceCommunicationPort, 
    GeocodingService, 
    NavigationRepository, 
    RouteService,
};
pub(crate) use infrastructure::protobuf_adapter::DeviceTransport;

// Modern API layer
mod api_v2;

// Re-export public APIs
pub use api_v2::{
    // Route APIs
    calculate_route,
    // Navigation APIs
    start_navigation_session,
    update_navigation_position,
    get_active_session,
    pause_navigation,
    resume_navigation,
    stop_navigation,
    // Geocoding APIs
    geocode_search,
    reverse_geocode,
};

use flutter_rust_bridge::frb;

// ============================================================================
// Diagnostic/Utility Functions
// ============================================================================

/// Simple ping function to verify FFI is working
#[frb]
pub fn ping() -> anyhow::Result<String> {
    Ok("pong - DDD architecture active".to_string())
}

/// Get architecture info
#[frb]
pub fn get_architecture_info() -> anyhow::Result<String> {
    Ok(serde_json::to_string(&serde_json::json!({
        "architecture": "DDD/Hexagonal/CQRS",
        "version": "2.0",
        "layers": ["domain", "application", "infrastructure"],
        "features": [
            "Route calculation",
            "Navigation sessions",
            "Geocoding",
            "Device communication (Protocol Buffers)",
            "Event sourcing"
        ]
    }))?)
}
