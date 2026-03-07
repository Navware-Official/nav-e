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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::application::{commands::*, queries::*};
    use crate::domain::{entities::NavigationStatus, value_objects::Position};
    use crate::infrastructure::{
        device::no_op_device_comm::NoOpDeviceComm,
        persistence::in_memory_repo::InMemoryNavigationRepository,
    };
    use nav_ir::*;

    // ── Test doubles ─────────────────────────────────────────────────────────

    struct FixedRouteService(NavIrRoute);

    #[async_trait]
    impl RouteService for FixedRouteService {
        async fn calculate_route(&self, _: Vec<Position>) -> Result<NavIrRoute> {
            Ok(self.0.clone())
        }
        async fn recalculate_from_position(&self, route: &NavIrRoute, _: Position) -> Result<NavIrRoute> {
            Ok(route.clone())
        }
    }

    struct FailingRouteService;

    #[async_trait]
    impl RouteService for FailingRouteService {
        async fn calculate_route(&self, _: Vec<Position>) -> Result<NavIrRoute> {
            anyhow::bail!("network error")
        }
        async fn recalculate_from_position(&self, _: &NavIrRoute, _: Position) -> Result<NavIrRoute> {
            anyhow::bail!("network error")
        }
    }

    struct FixedGeocodingService;

    #[async_trait]
    impl GeocodingService for FixedGeocodingService {
        async fn geocode(&self, _: &str) -> Result<Vec<Position>> {
            Ok(vec![Position::new(51.5, -0.12).unwrap()])
        }
        async fn reverse_geocode(&self, _: Position) -> Result<String> {
            Ok("1 Main St, London".to_string())
        }
    }

    fn make_route() -> NavIrRoute {
        use chrono::Utc;
        Route {
            schema_version: Route::CURRENT_SCHEMA_VERSION,
            id: RouteId::new(),
            metadata: RouteMetadata {
                name: "Test".into(), description: None,
                created_at: Utc::now(), updated_at: Utc::now(),
                total_distance_m: Some(1000.0), estimated_duration_s: Some(60),
                tags: vec![], source: None,
            },
            segments: vec![RouteSegment {
                id: SegmentId::new(),
                intent: SegmentIntent::Recalculatable,
                geometry: RouteGeometry {
                    polyline: EncodedPolyline("_p~iF~ps|U".into()),
                    source: GeometrySource::SnappedToGraph,
                    confidence: GeometryConfidence::High,
                    bounding_box: BoundingBox { min_lat: 40.0, min_lon: -74.0, max_lat: 41.0, max_lon: -73.0 },
                },
                waypoints: vec![
                    Waypoint { id: WaypointId::new(), coordinate: Coordinate::new(40.71, -74.01), kind: WaypointKind::Start, radius_m: None, name: None, description: None, role: None, category: None, geometry_ref: None },
                    Waypoint { id: WaypointId::new(), coordinate: Coordinate::new(40.76, -73.99), kind: WaypointKind::Stop, radius_m: None, name: None, description: None, role: None, category: None, geometry_ref: None },
                ],
                legs: vec![], instructions: vec![],
                constraints: SegmentConstraints::default(),
            }],
            policies: RoutePolicies::default(),
        }
    }

    fn repo() -> Arc<InMemoryNavigationRepository> {
        Arc::new(InMemoryNavigationRepository::new())
    }

    fn device_comm() -> Arc<NoOpDeviceComm> {
        Arc::new(NoOpDeviceComm)
    }

    fn pos(lat: f64, lon: f64) -> Position {
        Position::new(lat, lon).unwrap()
    }

    // ── StartNavigationHandler ───────────────────────────────────────────────

    #[tokio::test]
    async fn start_navigation_creates_active_session() {
        let route_svc = Arc::new(FixedRouteService(make_route()));
        let nav_repo = repo();
        let handler = StartNavigationHandler::new(route_svc, nav_repo.clone(), device_comm());

        let cmd = StartNavigationCommand {
            waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)],
            current_position: pos(40.71, -74.01),
            device_id: None,
        };

        let session = handler.handle(cmd).await.unwrap();
        assert_eq!(session.status, NavigationStatus::Active);

        // Session persisted
        let loaded = nav_repo.load_session(session.id).await.unwrap();
        assert!(loaded.is_some());
    }

    #[tokio::test]
    async fn start_navigation_fails_when_route_service_fails() {
        let handler = StartNavigationHandler::new(
            Arc::new(FailingRouteService),
            repo(),
            device_comm(),
        );
        let cmd = StartNavigationCommand {
            waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)],
            current_position: pos(40.71, -74.01),
            device_id: None,
        };
        assert!(handler.handle(cmd).await.is_err());
    }

    // ── PauseNavigationHandler ───────────────────────────────────────────────

    #[tokio::test]
    async fn pause_navigation_sets_paused_status() {
        let nav_repo = repo();
        let session = {
            let h = StartNavigationHandler::new(Arc::new(FixedRouteService(make_route())), nav_repo.clone(), device_comm());
            h.handle(StartNavigationCommand { waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)], current_position: pos(40.71, -74.01), device_id: None }).await.unwrap()
        };

        let pause_handler = PauseNavigationHandler::new(nav_repo.clone());
        pause_handler.handle(PauseNavigationCommand { session_id: session.id }).await.unwrap();

        let loaded = nav_repo.load_session(session.id).await.unwrap().unwrap();
        assert_eq!(loaded.status, NavigationStatus::Paused);
    }

    #[tokio::test]
    async fn pause_navigation_fails_for_unknown_session() {
        let handler = PauseNavigationHandler::new(repo());
        let result = handler.handle(PauseNavigationCommand { session_id: uuid::Uuid::new_v4() }).await;
        assert!(result.is_err());
    }

    // ── ResumeNavigationHandler ──────────────────────────────────────────────

    #[tokio::test]
    async fn resume_navigation_restores_active_status() {
        let nav_repo = repo();
        let session = {
            let h = StartNavigationHandler::new(Arc::new(FixedRouteService(make_route())), nav_repo.clone(), device_comm());
            h.handle(StartNavigationCommand { waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)], current_position: pos(40.71, -74.01), device_id: None }).await.unwrap()
        };
        PauseNavigationHandler::new(nav_repo.clone()).handle(PauseNavigationCommand { session_id: session.id }).await.unwrap();
        ResumeNavigationHandler::new(nav_repo.clone()).handle(ResumeNavigationCommand { session_id: session.id }).await.unwrap();

        let loaded = nav_repo.load_session(session.id).await.unwrap().unwrap();
        assert_eq!(loaded.status, NavigationStatus::Active);
    }

    // ── StopNavigationHandler ────────────────────────────────────────────────

    #[tokio::test]
    async fn stop_navigation_completed() {
        let nav_repo = repo();
        let session = {
            let h = StartNavigationHandler::new(Arc::new(FixedRouteService(make_route())), nav_repo.clone(), device_comm());
            h.handle(StartNavigationCommand { waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)], current_position: pos(40.71, -74.01), device_id: None }).await.unwrap()
        };
        StopNavigationHandler::new(nav_repo.clone())
            .handle(StopNavigationCommand { session_id: session.id, completed: true })
            .await.unwrap();
        let loaded = nav_repo.load_session(session.id).await.unwrap().unwrap();
        assert_eq!(loaded.status, NavigationStatus::Completed);
    }

    #[tokio::test]
    async fn stop_navigation_cancelled() {
        let nav_repo = repo();
        let session = {
            let h = StartNavigationHandler::new(Arc::new(FixedRouteService(make_route())), nav_repo.clone(), device_comm());
            h.handle(StartNavigationCommand { waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)], current_position: pos(40.71, -74.01), device_id: None }).await.unwrap()
        };
        StopNavigationHandler::new(nav_repo.clone())
            .handle(StopNavigationCommand { session_id: session.id, completed: false })
            .await.unwrap();
        let loaded = nav_repo.load_session(session.id).await.unwrap().unwrap();
        assert_eq!(loaded.status, NavigationStatus::Cancelled);
    }

    // ── UpdatePositionHandler ────────────────────────────────────────────────

    #[tokio::test]
    async fn update_position_persists_new_position() {
        let nav_repo = repo();
        let session = {
            let h = StartNavigationHandler::new(Arc::new(FixedRouteService(make_route())), nav_repo.clone(), device_comm());
            h.handle(StartNavigationCommand { waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)], current_position: pos(40.71, -74.01), device_id: None }).await.unwrap()
        };
        let new_pos = pos(40.73, -74.00);
        UpdatePositionHandler::new(nav_repo.clone(), device_comm())
            .handle(UpdatePositionCommand { session_id: session.id, position: new_pos })
            .await.unwrap();
        let loaded = nav_repo.load_session(session.id).await.unwrap().unwrap();
        assert_eq!(loaded.current_position, new_pos);
    }

    // ── GetActiveSessionHandler ──────────────────────────────────────────────

    #[tokio::test]
    async fn get_active_session_returns_none_when_empty() {
        let handler = GetActiveSessionHandler::new(repo());
        let result = handler.handle(GetActiveSessionQuery {}).await.unwrap();
        assert!(result.is_none());
    }

    #[tokio::test]
    async fn get_active_session_returns_active_session() {
        let nav_repo = repo();
        let session = {
            let h = StartNavigationHandler::new(Arc::new(FixedRouteService(make_route())), nav_repo.clone(), device_comm());
            h.handle(StartNavigationCommand { waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)], current_position: pos(40.71, -74.01), device_id: None }).await.unwrap()
        };
        let found = GetActiveSessionHandler::new(nav_repo).handle(GetActiveSessionQuery {}).await.unwrap();
        assert_eq!(found.unwrap().id, session.id);
    }

    // ── CalculateRouteHandler ────────────────────────────────────────────────

    #[tokio::test]
    async fn calculate_route_returns_route() {
        let expected = make_route();
        let handler = CalculateRouteHandler::new(Arc::new(FixedRouteService(expected.clone())));
        let result = handler.handle(CalculateRouteQuery {
            waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)],
        }).await.unwrap();
        assert_eq!(result.id, expected.id);
    }

    // ── GeocodeHandler / ReverseGeocodeHandler ───────────────────────────────

    #[tokio::test]
    async fn geocode_handler_returns_positions() {
        let handler = GeocodeHandler::new(Arc::new(FixedGeocodingService));
        let result = handler.handle(GeocodeQuery { address: "London".into() }).await.unwrap();
        assert_eq!(result.len(), 1);
        assert!((result[0].latitude - 51.5).abs() < 0.01);
    }

    #[tokio::test]
    async fn reverse_geocode_handler_returns_address() {
        let handler = ReverseGeocodeHandler::new(Arc::new(FixedGeocodingService));
        let result = handler.handle(ReverseGeocodeQuery { position: pos(51.5, -0.12) }).await.unwrap();
        assert!(result.contains("London"));
    }
}
