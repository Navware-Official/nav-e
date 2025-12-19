// Ports - Interfaces for external dependencies (Hexagonal Architecture)
use crate::domain::{entities::*, value_objects::*};
use anyhow::Result;
use async_trait::async_trait;

// ============================================================================
// Generic Repository Pattern
// ============================================================================

/// Generic repository trait for common CRUD operations
///
/// This trait provides a standard interface for all repositories,
/// reducing boilerplate and ensuring consistency.
///
/// # Type Parameters
/// - `T`: The entity type
/// - `ID`: The identifier type (typically i64 for SQLite)
pub trait Repository<T, ID>: Send + Sync {
    /// Get all entities
    fn get_all(&self) -> Result<Vec<T>>;

    /// Get an entity by its ID
    fn get_by_id(&self, id: ID) -> Result<Option<T>>;

    /// Insert a new entity and return its assigned ID
    fn insert(&self, entity: T) -> Result<ID>;

    /// Update an existing entity
    fn update(&self, id: ID, entity: T) -> Result<()>;

    /// Delete an entity by its ID
    fn delete(&self, id: ID) -> Result<()>;
}

// ============================================================================
// Service Ports
// ============================================================================

/// Port for route calculation service
#[async_trait]
pub trait RouteService: Send + Sync {
    async fn calculate_route(&self, waypoints: Vec<Position>) -> Result<Route>;
    async fn recalculate_from_position(
        &self,
        route: &Route,
        current_position: Position,
    ) -> Result<Route>;
}

/// Port for geocoding service
#[async_trait]
pub trait GeocodingService: Send + Sync {
    async fn geocode(&self, address: &str) -> Result<Vec<Position>>;
    async fn reverse_geocode(&self, position: Position) -> Result<String>;
}

/// Port for device communication (primary port - driving side)
#[async_trait]
pub trait DeviceCommunicationPort: Send + Sync {
    async fn send_route_summary(
        &self,
        device_id: String,
        session: &NavigationSession,
    ) -> Result<()>;
    async fn send_route_blob(&self, device_id: String, route: &Route) -> Result<()>;
    async fn send_position_update(&self, device_id: String, position: Position) -> Result<()>;
    async fn send_traffic_alert(&self, device_id: String, event: &TrafficEvent) -> Result<()>;
    async fn send_control_command(&self, device_id: String, command: ControlCommand) -> Result<()>;
}

/// Port for receiving device messages (secondary port - driven side)
#[async_trait]
pub trait DeviceMessageReceiver: Send + Sync {
    async fn on_position_update(&self, device_id: String, position: Position) -> Result<()>;
    async fn on_control_received(&self, device_id: String, command: ControlCommand) -> Result<()>;
    async fn on_device_capabilities(
        &self,
        device_id: String,
        capabilities: DeviceCapabilities,
    ) -> Result<()>;
    async fn on_battery_status(&self, device_id: String, battery: BatteryInfo) -> Result<()>;
}

/// Port for navigation state persistence
#[async_trait]
pub trait NavigationRepository: Send + Sync {
    async fn save_session(&self, session: &NavigationSession) -> Result<()>;
    async fn load_session(&self, id: uuid::Uuid) -> Result<Option<NavigationSession>>;
    async fn load_active_session(&self) -> Result<Option<NavigationSession>>;
    async fn delete_session(&self, id: uuid::Uuid) -> Result<()>;
}

/// Port for traffic information
#[async_trait]
pub trait TrafficService: Send + Sync {
    async fn get_traffic_alerts(&self, route: &Route) -> Result<Vec<TrafficEvent>>;
    async fn subscribe_to_traffic(&self, route_id: uuid::Uuid) -> Result<()>;
}

/// Control commands for navigation

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ControlCommand {
    StartNavigation,
    PauseNavigation,
    ResumeNavigation,
    StopNavigation,
    Acknowledge,
    NegativeAcknowledge,
    Heartbeat,
}
