// Service helpers for reducing boilerplate in handlers
use crate::domain::ports::*;
use anyhow::Result;
use std::sync::Arc;

/// Builder for creating handlers with common dependencies
/// This reduces boilerplate when instantiating handlers in API layer
pub struct ServiceRegistry {
    pub route_service: Arc<dyn RouteService>,
    pub geocoding_service: Arc<dyn GeocodingService>,
    pub navigation_repo: Arc<dyn NavigationRepository>,
}

impl ServiceRegistry {
    pub fn new(
        route_service: Arc<dyn RouteService>,
        geocoding_service: Arc<dyn GeocodingService>,
        navigation_repo: Arc<dyn NavigationRepository>,
    ) -> Self {
        Self {
            route_service,
            geocoding_service,
            navigation_repo,
        }
    }
}

/// Macro to reduce boilerplate when executing handlers
/// Usage: execute_handler!(handler, command/query)
#[macro_export]
macro_rules! execute_command {
    ($handler:expr, $command:expr) => {
        $crate::application::traits::CommandHandler::handle(&$handler, $command).await
    };
}

#[macro_export]
macro_rules! execute_query {
    ($handler:expr, $query:expr) => {
        $crate::application::traits::QueryHandler::handle(&$handler, $query).await
    };
}

/// Helper function to execute a command handler with error context
pub async fn execute_command_with_context<TCommand, TResult, H>(
    handler: &H,
    command: TCommand,
    context_msg: &str,
) -> Result<TResult>
where
    H: crate::application::traits::CommandHandler<TCommand, TResult>,
{
    handler
        .handle(command)
        .await
        .with_context(|| context_msg.to_string())
}

/// Helper function to execute a query handler with error context
pub async fn execute_query_with_context<TQuery, TResult, H>(
    handler: &H,
    query: TQuery,
    context_msg: &str,
) -> Result<TResult>
where
    H: crate::application::traits::QueryHandler<TQuery, TResult>,
{
    handler
        .handle(query)
        .await
        .with_context(|| context_msg.to_string())
}

use anyhow::Context;
