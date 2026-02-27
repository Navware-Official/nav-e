#![allow(dead_code)]
// Command and Query Handlers - Application logic
use crate::application::{commands::*, queries::*, traits::*};
use crate::domain::{entities::*, events::*, ports::*, value_objects::*};
use anyhow::{Context, Result};
use async_trait::async_trait;
use nav_ir::Route as NavIrRoute;
use std::sync::Arc;

/// Command handler for StartNavigationCommand
pub struct StartNavigationHandler {
    route_service: Arc<dyn RouteService>,
    navigation_repo: Arc<dyn NavigationRepository>,
    device_comm: Arc<dyn DeviceCommunicationPort>,
}

impl StartNavigationHandler {
    pub fn new(
        route_service: Arc<dyn RouteService>,
        navigation_repo: Arc<dyn NavigationRepository>,
        device_comm: Arc<dyn DeviceCommunicationPort>,
    ) -> Self {
        Self {
            route_service,
            navigation_repo,
            device_comm,
        }
    }
}

#[async_trait]
impl CommandHandler<StartNavigationCommand, NavigationSession> for StartNavigationHandler {
    async fn handle(&self, command: StartNavigationCommand) -> Result<NavigationSession> {
        // Calculate route
        let route = self
            .route_service
            .calculate_route(command.waypoints)
            .await
            .context("Failed to calculate route")?;

        // Create session
        let session = NavigationSession::new(route.clone(), command.current_position);

        // Persist session
        self.navigation_repo
            .save_session(&session)
            .await
            .context("Failed to save navigation session")?;

        // Send to device if specified
        if let Some(device_id) = command.device_id {
            self.device_comm
                .send_route_blob(device_id, &route)
                .await
                .ok(); // Don't fail if device send fails
        }

        // Publish domain event
        let _event = NavigationStartedEvent::new(session.id, route.id.0);
        // TODO: Publish to event bus

        Ok(session)
    }
}

/// Command handler for UpdatePositionCommand
pub struct UpdatePositionHandler {
    navigation_repo: Arc<dyn NavigationRepository>,
    device_comm: Arc<dyn DeviceCommunicationPort>,
}

impl UpdatePositionHandler {
    pub fn new(
        navigation_repo: Arc<dyn NavigationRepository>,
        device_comm: Arc<dyn DeviceCommunicationPort>,
    ) -> Self {
        Self {
            navigation_repo,
            device_comm,
        }
    }
}

#[async_trait]
impl CommandHandler<UpdatePositionCommand, ()> for UpdatePositionHandler {
    async fn handle(&self, command: UpdatePositionCommand) -> Result<()> {
        // Load session
        let mut session = self
            .navigation_repo
            .load_session(command.session_id)
            .await?
            .context("Navigation session not found")?;

        // Update position
        session.update_position(command.position);

        // Save updated session
        self.navigation_repo.save_session(&session).await?;

        // Check for waypoint proximity (simplified - 50m threshold)
        let mut waypoint_index = 0usize;
        for segment in session.route.segments.iter() {
            for wp in segment.waypoints.iter() {
                let pos = Position::new(wp.coordinate.latitude, wp.coordinate.longitude)
                    .unwrap_or_else(|_| command.position);
                if command.position.distance_to(&pos) < 50.0 {
                    let _event =
                        WaypointReachedEvent::new(session.id, waypoint_index, command.position);
                    // TODO: Publish event
                    break;
                }
                waypoint_index += 1;
            }
        }

        // Publish position updated event
        let _event = PositionUpdatedEvent::new(session.id, command.position);
        // TODO: Publish to event bus

        Ok(())
    }
}

/// Command handler for PauseNavigationCommand
pub struct PauseNavigationHandler {
    navigation_repo: Arc<dyn NavigationRepository>,
}

impl PauseNavigationHandler {
    pub fn new(navigation_repo: Arc<dyn NavigationRepository>) -> Self {
        Self { navigation_repo }
    }
}

#[async_trait]
impl CommandHandler<PauseNavigationCommand, ()> for PauseNavigationHandler {
    async fn handle(&self, command: PauseNavigationCommand) -> Result<()> {
        let mut session = self
            .navigation_repo
            .load_session(command.session_id)
            .await?
            .context("Navigation session not found")?;

        session.pause();
        self.navigation_repo.save_session(&session).await?;

        Ok(())
    }
}

/// Command handler for ResumeNavigationCommand
pub struct ResumeNavigationHandler {
    navigation_repo: Arc<dyn NavigationRepository>,
}

impl ResumeNavigationHandler {
    pub fn new(navigation_repo: Arc<dyn NavigationRepository>) -> Self {
        Self { navigation_repo }
    }
}

#[async_trait]
impl CommandHandler<ResumeNavigationCommand, ()> for ResumeNavigationHandler {
    async fn handle(&self, command: ResumeNavigationCommand) -> Result<()> {
        let mut session = self
            .navigation_repo
            .load_session(command.session_id)
            .await?
            .context("Navigation session not found")?;

        session.resume();
        self.navigation_repo.save_session(&session).await?;

        Ok(())
    }
}

/// Command handler for StopNavigationCommand
pub struct StopNavigationHandler {
    navigation_repo: Arc<dyn NavigationRepository>,
}

impl StopNavigationHandler {
    pub fn new(navigation_repo: Arc<dyn NavigationRepository>) -> Self {
        Self { navigation_repo }
    }
}

#[async_trait]
impl CommandHandler<StopNavigationCommand, ()> for StopNavigationHandler {
    async fn handle(&self, command: StopNavigationCommand) -> Result<()> {
        let mut session = self
            .navigation_repo
            .load_session(command.session_id)
            .await?
            .context("Navigation session not found")?;

        if command.completed {
            session.complete();
            let distance_m = session.route.metadata.total_distance_m.unwrap_or(0.0);
            let duration_s = session
                .route
                .metadata
                .estimated_duration_s
                .map(|s| s as u32)
                .unwrap_or(0);
            let _event = NavigationCompletedEvent::new(session.id, distance_m, duration_s);
            // TODO: Publish event
        } else {
            session.status = NavigationStatus::Cancelled;
        }

        self.navigation_repo.save_session(&session).await?;

        Ok(())
    }
}

/// Query handler for GetActiveSessionQuery
pub struct GetActiveSessionHandler {
    navigation_repo: Arc<dyn NavigationRepository>,
}

impl GetActiveSessionHandler {
    pub fn new(navigation_repo: Arc<dyn NavigationRepository>) -> Self {
        Self { navigation_repo }
    }
}

#[async_trait]
impl QueryHandler<GetActiveSessionQuery, Option<NavigationSession>> for GetActiveSessionHandler {
    async fn handle(&self, _query: GetActiveSessionQuery) -> Result<Option<NavigationSession>> {
        self.navigation_repo.load_active_session().await
    }
}

/// Query handler for CalculateRouteQuery
pub struct CalculateRouteHandler {
    route_service: Arc<dyn RouteService>,
}

impl CalculateRouteHandler {
    pub fn new(route_service: Arc<dyn RouteService>) -> Self {
        Self { route_service }
    }
}

#[async_trait]
impl QueryHandler<CalculateRouteQuery, NavIrRoute> for CalculateRouteHandler {
    async fn handle(&self, query: CalculateRouteQuery) -> Result<NavIrRoute> {
        self.route_service.calculate_route(query.waypoints).await
    }
}

/// Query handler for GeocodeQuery
pub struct GeocodeHandler {
    geocoding_service: Arc<dyn GeocodingService>,
}

impl GeocodeHandler {
    pub fn new(geocoding_service: Arc<dyn GeocodingService>) -> Self {
        Self { geocoding_service }
    }
}

#[async_trait]
impl QueryHandler<GeocodeQuery, Vec<Position>> for GeocodeHandler {
    async fn handle(&self, query: GeocodeQuery) -> Result<Vec<Position>> {
        self.geocoding_service.geocode(&query.address).await
    }
}

/// Query handler for ReverseGeocodeQuery
pub struct ReverseGeocodeHandler {
    geocoding_service: Arc<dyn GeocodingService>,
}

impl ReverseGeocodeHandler {
    pub fn new(geocoding_service: Arc<dyn GeocodingService>) -> Self {
        Self { geocoding_service }
    }
}

#[async_trait]
impl QueryHandler<ReverseGeocodeQuery, String> for ReverseGeocodeHandler {
    async fn handle(&self, query: ReverseGeocodeQuery) -> Result<String> {
        self.geocoding_service.reverse_geocode(query.position).await
    }
}
