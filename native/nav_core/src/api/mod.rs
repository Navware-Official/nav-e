/// API module - Feature-based organization
///
/// This module provides the API surface organized by feature/domain.
/// Clean, type-safe, and follows domain-driven design principles.
mod context;
pub use context::*;

pub mod dto;
pub mod helpers;

// Feature modules - public for FRB-generated code but not re-exported from crate
pub(crate) mod device;
pub(crate) mod geocoding;
pub(crate) mod navigation;
pub(crate) mod offline_regions;
pub(crate) mod places;

// Re-export all public APIs
pub use device::*;
pub use geocoding::*;
pub use navigation::*;
pub use offline_regions::*;
pub use places::*;

// Re-export helpers for use in API functions
pub use helpers::*;
