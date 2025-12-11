// Application Layer - Use cases and orchestration (CQRS)
pub mod commands;
pub mod queries;
pub mod handlers;
pub mod traits;
pub mod service_helpers;

// Re-export common traits and helpers
pub use traits::{CommandHandler, QueryHandler, SyncCommandHandler, SyncQueryHandler};
pub use service_helpers::ServiceRegistry;
