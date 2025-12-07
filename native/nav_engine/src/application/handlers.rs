// Command and Query Handlers - Application logic
use crate::application::{commands::*, queries::*};
use crate::domain::{entities::*, events::*, ports::*, value_objects::*};
use anyhow::{Context, Result};
use async_trait::async_trait;
use flutter_rust_bridge::frb;
use std::sync::Arc;
use uuid::Uuid;

/// Command handler for StartNavigationCommand
#[frb(ignore)]
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

    pub async fn handle(&self, command: StartNavigationCommand) -> Result<NavigationSession> {
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
        let _event = NavigationStartedEvent::new(session.id, route.id);
        // TODO: Publish to event bus

        Ok(session)
    }
}

/// Command handler for UpdatePositionCommand
#[frb(ignore)]
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

    pub async fn handle(&self, command: UpdatePositionCommand) -> Result<()> {
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
        for (idx, waypoint) in session.route.waypoints.iter().enumerate() {
            if !waypoint.is_visited {
                let distance = command.position.distance_to(&waypoint.position);
                if distance < 50.0 {
                    let _event = WaypointReachedEvent::new(session.id, idx, command.position);
                    // TODO: Publish event
                    break;
                }
            }
        }

        // Publish position updated event
        let _event = PositionUpdatedEvent::new(session.id, command.position);
        // TODO: Publish to event bus

        Ok(())
    }
}

/// Command handler for PauseNavigationCommand
#[frb(ignore)]
pub struct PauseNavigationHandler {
    navigation_repo: Arc<dyn NavigationRepository>,
}

impl PauseNavigationHandler {
    pub fn new(navigation_repo: Arc<dyn NavigationRepository>) -> Self {
        Self { navigation_repo }
    }

    pub async fn handle(&self, command: PauseNavigationCommand) -> Result<()> {
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
#[frb(ignore)]
pub struct ResumeNavigationHandler {
    navigation_repo: Arc<dyn NavigationRepository>,
}

impl ResumeNavigationHandler {
    pub fn new(navigation_repo: Arc<dyn NavigationRepository>) -> Self {
        Self { navigation_repo }
    }

    pub async fn handle(&self, command: ResumeNavigationCommand) -> Result<()> {
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
#[frb(ignore)]
pub struct StopNavigationHandler {
    navigation_repo: Arc<dyn NavigationRepository>,
}

impl StopNavigationHandler {
    pub fn new(navigation_repo: Arc<dyn NavigationRepository>) -> Self {
        Self { navigation_repo }
    }

    pub async fn handle(&self, command: StopNavigationCommand) -> Result<()> {
        let mut session = self
            .navigation_repo
            .load_session(command.session_id)
            .await?
            .context("Navigation session not found")?;

        if command.completed {
            session.complete();
            let _event = NavigationCompletedEvent::new(
                session.id,
                session.route.distance_meters,
                session.route.duration_seconds,
            );
            // TODO: Publish event
        } else {
            session.status = NavigationStatus::Cancelled;
        }

        self.navigation_repo.save_session(&session).await?;

        Ok(())
    }
}

/// Query handler for GetActiveSessionQuery
#[frb(ignore)]
pub struct GetActiveSessionHandler {
    navigation_repo: Arc<dyn NavigationRepository>,
}

impl GetActiveSessionHandler {
    pub fn new(navigation_repo: Arc<dyn NavigationRepository>) -> Self {
        Self { navigation_repo }
    }

    pub async fn handle(&self, _query: GetActiveSessionQuery) -> Result<Option<NavigationSession>> {
        self.navigation_repo.load_active_session().await
    }
}

/// Query handler for CalculateRouteQuery
#[frb(ignore)]
pub struct CalculateRouteHandler {
    route_service: Arc<dyn RouteService>,
}

impl CalculateRouteHandler {
    pub fn new(route_service: Arc<dyn RouteService>) -> Self {
        Self { route_service }
    }

    pub async fn handle(&self, query: CalculateRouteQuery) -> Result<Route> {
        self.route_service.calculate_route(query.waypoints).await
    }
}

/// Query handler for GeocodeQuery
#[frb(ignore)]
pub struct GeocodeHandler {
    geocoding_service: Arc<dyn GeocodingService>,
}

impl GeocodeHandler {
    pub fn new(geocoding_service: Arc<dyn GeocodingService>) -> Self {
        Self { geocoding_service }
    }

    pub async fn handle(&self, query: GeocodeQuery) -> Result<Vec<Position>> {
        self.geocoding_service.geocode(&query.address).await
    }
}

/// Query handler for ReverseGeocodeQuery
#[frb(ignore)]
pub struct ReverseGeocodeHandler {
    geocoding_service: Arc<dyn GeocodingService>,
}

impl ReverseGeocodeHandler {
    pub fn new(geocoding_service: Arc<dyn GeocodingService>) -> Self {
        Self { geocoding_service }
    }

    pub async fn handle(&self, query: ReverseGeocodeQuery) -> Result<String> {
        self.geocoding_service.reverse_geocode(query.position).await
    }
}
