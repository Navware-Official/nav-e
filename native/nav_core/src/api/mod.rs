/// API module - Feature-based organization
///
/// This module provides the API surface organized by feature/domain.
/// Clean, type-safe, and follows domain-driven design principles.
mod context;
pub use context::*;

pub mod dto;
pub mod helpers;

// Feature modules - pub so items can be re-exported and reached by FRB-generated code
pub mod device;
pub mod geocoding;
pub mod navigation;
pub mod offline_regions;
pub mod places;

// Re-export all public APIs
pub use device::*;
pub use geocoding::*;
pub use navigation::*;
pub use offline_regions::*;
pub use places::*;

// Re-export helpers for use in API functions
pub use helpers::*;
