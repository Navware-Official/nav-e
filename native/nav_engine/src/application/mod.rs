// Application Layer - Use cases and orchestration (CQRS)
pub mod commands;
pub mod handlers;
pub mod queries;
pub mod service_helpers;
pub mod traits;

// Re-export common traits and helpers
pub use service_helpers::ServiceRegistry;
pub use traits::{CommandHandler, QueryHandler, SyncCommandHandler, SyncQueryHandler};
