// Generic handler traits for CQRS pattern
use anyhow::Result;
use async_trait::async_trait;

/// Generic trait for command handlers (write operations)
/// Commands modify state and may produce side effects
#[async_trait]
pub trait CommandHandler<TCommand, TResult> {
    async fn handle(&self, command: TCommand) -> Result<TResult>;
}

/// Generic trait for query handlers (read operations)
/// Queries don't modify state and have no side effects
#[async_trait]
pub trait QueryHandler<TQuery, TResult> {
    async fn handle(&self, query: TQuery) -> Result<TResult>;
}

/// Synchronous command handler for operations that don't require async
pub trait SyncCommandHandler<TCommand, TResult> {
    fn handle(&self, command: TCommand) -> Result<TResult>;
}

/// Synchronous query handler for operations that don't require async
pub trait SyncQueryHandler<TQuery, TResult> {
    fn handle(&self, query: TQuery) -> Result<TResult>;
}
