// Command and Query Handlers - Application logic
use crate::navigation::application::{commands::*, queries::*};
use crate::navigation::domain::{events::NavigationEvent, ports::*, session::*};
use crate::shared::value_objects::*;
use anyhow::{Context, Result};
use std::sync::Arc;
use tokio::sync::broadcast;

// ── Aggregated handler structs ────────────────────────────────────────────────

/// Pre-constructed navigation application service.
///
/// Held for the lifetime of the app in `AppContainer`. All navigation API
/// functions dispatch through this struct — no per-call handler construction.
pub struct NavigationHandlers {
    route_service: Arc<dyn RouteService>,
    start_handler: StartNavigationHandler,
    update_position_handler: UpdatePositionHandler,
    pause_handler: PauseNavigationHandler,
    resume_handler: ResumeNavigationHandler,
    stop_handler: StopNavigationHandler,
    get_active_handler: GetActiveSessionHandler,
    event_bus: broadcast::Sender<NavigationEvent>,
}

impl NavigationHandlers {
    pub fn new(
        route_service: Arc<dyn RouteService>,
        navigation_repo: Arc<dyn NavigationRepository>,
        device_comm: Arc<dyn DeviceCommunicationPort>,
        event_bus: broadcast::Sender<NavigationEvent>,
    ) -> Self {
        Self {
            start_handler: StartNavigationHandler::new(
                Arc::clone(&route_service),
                Arc::clone(&navigation_repo),
                Arc::clone(&device_comm),
                event_bus.clone(),
            ),
            update_position_handler: UpdatePositionHandler::new(
                Arc::clone(&navigation_repo),
                event_bus.clone(),
            ),
            pause_handler: PauseNavigationHandler::new(Arc::clone(&navigation_repo)),
            resume_handler: ResumeNavigationHandler::new(Arc::clone(&navigation_repo)),
            stop_handler: StopNavigationHandler::new(
                Arc::clone(&navigation_repo),
                event_bus.clone(),
            ),
            get_active_handler: GetActiveSessionHandler::new(navigation_repo),
            route_service,
            event_bus,
        }
    }

    pub async fn calculate_route(&self, waypoints: Vec<Position>) -> Result<nav_ir::Route> {
        self.route_service.calculate_route(waypoints).await
    }

    pub async fn start(&self, cmd: StartNavigationCommand) -> Result<NavigationSession> {
        self.start_handler.handle(cmd).await
    }

    pub async fn update_position(&self, cmd: UpdatePositionCommand) -> Result<()> {
        self.update_position_handler.handle(cmd).await
    }

    pub async fn pause(&self, cmd: PauseNavigationCommand) -> Result<()> {
        self.pause_handler.handle(cmd).await
    }

    pub async fn resume(&self, cmd: ResumeNavigationCommand) -> Result<()> {
        self.resume_handler.handle(cmd).await
    }

    pub async fn stop(&self, cmd: StopNavigationCommand) -> Result<()> {
        self.stop_handler.handle(cmd).await
    }

    pub async fn get_active(&self, q: GetActiveSessionQuery) -> Result<Option<NavigationSession>> {
        self.get_active_handler.handle(q).await
    }

    pub fn subscribe(&self) -> broadcast::Receiver<NavigationEvent> {
        self.event_bus.subscribe()
    }
}

/// Pre-constructed geocoding application service.
///
/// Held for the lifetime of the app in `AppContainer`.
pub struct GeocodingHandlers {
    geocode_handler: GeocodeHandler,
    reverse_geocode_handler: ReverseGeocodeHandler,
}

impl GeocodingHandlers {
    pub fn new(geocoding_service: Arc<dyn GeocodingService>) -> Self {
        Self {
            geocode_handler: GeocodeHandler::new(Arc::clone(&geocoding_service)),
            reverse_geocode_handler: ReverseGeocodeHandler::new(geocoding_service),
        }
    }

    pub async fn geocode(&self, q: GeocodeQuery) -> Result<Vec<GeocodingSearchResult>> {
        self.geocode_handler.handle(q).await
    }

    pub async fn reverse_geocode(&self, q: ReverseGeocodeQuery) -> Result<String> {
        self.reverse_geocode_handler.handle(q).await
    }
}

/// Command handler for StartNavigationCommand
pub struct StartNavigationHandler {
    route_service: Arc<dyn RouteService>,
    navigation_repo: Arc<dyn NavigationRepository>,
    device_comm: Arc<dyn DeviceCommunicationPort>,
    event_bus: broadcast::Sender<NavigationEvent>,
}

impl StartNavigationHandler {
    pub fn new(
        route_service: Arc<dyn RouteService>,
        navigation_repo: Arc<dyn NavigationRepository>,
        device_comm: Arc<dyn DeviceCommunicationPort>,
        event_bus: broadcast::Sender<NavigationEvent>,
    ) -> Self {
        Self {
            route_service,
            navigation_repo,
            device_comm,
            event_bus,
        }
    }
}

impl StartNavigationHandler {
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

        let _ = self.event_bus.send(NavigationEvent::Started {
            session_id: session.id,
            route_id: route.id.0,
        });

        Ok(session)
    }
}

/// Command handler for UpdatePositionCommand
pub struct UpdatePositionHandler {
    navigation_repo: Arc<dyn NavigationRepository>,
    event_bus: broadcast::Sender<NavigationEvent>,
}

impl UpdatePositionHandler {
    pub fn new(
        navigation_repo: Arc<dyn NavigationRepository>,
        event_bus: broadcast::Sender<NavigationEvent>,
    ) -> Self {
        Self {
            navigation_repo,
            event_bus,
        }
    }
}

impl UpdatePositionHandler {
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
        let mut waypoint_index = 0usize;
        'outer: for segment in session.route.segments.iter() {
            for wp in segment.waypoints.iter() {
                let pos = Position::new(wp.coordinate.latitude, wp.coordinate.longitude)
                    .unwrap_or_else(|_| command.position);
                if command.position.distance_to(&pos) < 50.0 {
                    let _ = self.event_bus.send(NavigationEvent::WaypointReached {
                        session_id: session.id,
                        index: waypoint_index,
                    });
                    break 'outer;
                }
                waypoint_index += 1;
            }
        }

        let _ = self.event_bus.send(NavigationEvent::PositionUpdated {
            session_id: session.id,
            position: command.position,
        });

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

impl PauseNavigationHandler {
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
pub struct ResumeNavigationHandler {
    navigation_repo: Arc<dyn NavigationRepository>,
}

impl ResumeNavigationHandler {
    pub fn new(navigation_repo: Arc<dyn NavigationRepository>) -> Self {
        Self { navigation_repo }
    }
}

impl ResumeNavigationHandler {
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
pub struct StopNavigationHandler {
    navigation_repo: Arc<dyn NavigationRepository>,
    event_bus: broadcast::Sender<NavigationEvent>,
}

impl StopNavigationHandler {
    pub fn new(
        navigation_repo: Arc<dyn NavigationRepository>,
        event_bus: broadcast::Sender<NavigationEvent>,
    ) -> Self {
        Self {
            navigation_repo,
            event_bus,
        }
    }
}

impl StopNavigationHandler {
    pub async fn handle(&self, command: StopNavigationCommand) -> Result<()> {
        let mut session = self
            .navigation_repo
            .load_session(command.session_id)
            .await?
            .context("Navigation session not found")?;

        if command.completed {
            session.complete();
            let distance_m = session.route.metadata.total_distance_m.unwrap_or(0.0);
            let _ = self.event_bus.send(NavigationEvent::Completed {
                session_id: session.id,
                distance_m,
            });
        } else {
            session.status = NavigationStatus::Cancelled;
            let _ = self.event_bus.send(NavigationEvent::Cancelled {
                session_id: session.id,
            });
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

impl GetActiveSessionHandler {
    pub async fn handle(&self, _query: GetActiveSessionQuery) -> Result<Option<NavigationSession>> {
        self.navigation_repo.load_active_session().await
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

impl GeocodeHandler {
    pub async fn handle(&self, query: GeocodeQuery) -> Result<Vec<GeocodingSearchResult>> {
        self.geocoding_service
            .geocode(&query.address, query.limit)
            .await
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

impl ReverseGeocodeHandler {
    pub async fn handle(&self, query: ReverseGeocodeQuery) -> Result<String> {
        self.geocoding_service.reverse_geocode(query.position).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::infrastructure::{
        device::no_op_device_comm::NoOpDeviceComm,
        persistence::in_memory_repo::InMemoryNavigationRepository,
    };
    use crate::navigation::domain::session::NavigationStatus;
    use crate::shared::value_objects::Position;
    use async_trait::async_trait;
    use nav_ir::*;

    // ── Test doubles ─────────────────────────────────────────────────────────

    struct FixedRouteService(Route);

    #[async_trait]
    impl RouteService for FixedRouteService {
        async fn calculate_route(&self, _: Vec<Position>) -> Result<Route> {
            Ok(self.0.clone())
        }
        async fn recalculate_from_position(&self, route: &Route, _: Position) -> Result<Route> {
            Ok(route.clone())
        }
    }

    struct FailingRouteService;

    #[async_trait]
    impl RouteService for FailingRouteService {
        async fn calculate_route(&self, _: Vec<Position>) -> Result<Route> {
            anyhow::bail!("network error")
        }
        async fn recalculate_from_position(&self, _: &Route, _: Position) -> Result<Route> {
            anyhow::bail!("network error")
        }
    }

    struct FixedGeocodingService;

    #[async_trait]
    impl GeocodingService for FixedGeocodingService {
        async fn geocode(&self, _: &str, _: Option<u32>) -> Result<Vec<GeocodingSearchResult>> {
            Ok(vec![GeocodingSearchResult {
                position: Position::new(51.5, -0.12).unwrap(),
                display_name: "London, England".to_string(),
                name: Some("London".to_string()),
                city: Some("London".to_string()),
                country: Some("United Kingdom".to_string()),
                osm_type: None,
                osm_id: None,
            }])
        }
        async fn reverse_geocode(&self, _: Position) -> Result<String> {
            Ok("1 Main St, London".to_string())
        }
    }

    fn make_route() -> Route {
        use chrono::Utc;
        Route {
            schema_version: Route::CURRENT_SCHEMA_VERSION,
            id: RouteId::new(),
            metadata: RouteMetadata {
                name: "Test".into(),
                description: None,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                total_distance_m: Some(1000.0),
                estimated_duration_s: Some(60),
                tags: vec![],
                source: None,
            },
            segments: vec![RouteSegment {
                id: SegmentId::new(),
                intent: SegmentIntent::Recalculatable,
                geometry: RouteGeometry {
                    polyline: EncodedPolyline("_p~iF~ps|U".into()),
                    source: GeometrySource::SnappedToGraph,
                    confidence: GeometryConfidence::High,
                    bounding_box: BoundingBox {
                        min_lat: 40.0,
                        min_lon: -74.0,
                        max_lat: 41.0,
                        max_lon: -73.0,
                    },
                },
                waypoints: vec![
                    Waypoint {
                        id: WaypointId::new(),
                        coordinate: Coordinate::new(40.71, -74.01),
                        kind: WaypointKind::Start,
                        radius_m: None,
                        name: None,
                        description: None,
                        role: None,
                        category: None,
                        geometry_ref: None,
                    },
                    Waypoint {
                        id: WaypointId::new(),
                        coordinate: Coordinate::new(40.76, -73.99),
                        kind: WaypointKind::Stop,
                        radius_m: None,
                        name: None,
                        description: None,
                        role: None,
                        category: None,
                        geometry_ref: None,
                    },
                ],
                legs: vec![],
                instructions: vec![],
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

    fn event_bus() -> broadcast::Sender<NavigationEvent> {
        broadcast::channel(8).0
    }

    fn pos(lat: f64, lon: f64) -> Position {
        Position::new(lat, lon).unwrap()
    }

    // ── StartNavigationHandler ───────────────────────────────────────────────

    #[tokio::test]
    async fn start_navigation_creates_active_session() {
        let route_svc = Arc::new(FixedRouteService(make_route()));
        let nav_repo = repo();
        let handler =
            StartNavigationHandler::new(route_svc, nav_repo.clone(), device_comm(), event_bus());

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
            event_bus(),
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
            let h = StartNavigationHandler::new(
                Arc::new(FixedRouteService(make_route())),
                nav_repo.clone(),
                device_comm(),
                event_bus(),
            );
            h.handle(StartNavigationCommand {
                waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)],
                current_position: pos(40.71, -74.01),
                device_id: None,
            })
            .await
            .unwrap()
        };

        let pause_handler = PauseNavigationHandler::new(nav_repo.clone());
        pause_handler
            .handle(PauseNavigationCommand {
                session_id: session.id,
            })
            .await
            .unwrap();

        let loaded = nav_repo.load_session(session.id).await.unwrap().unwrap();
        assert_eq!(loaded.status, NavigationStatus::Paused);
    }

    #[tokio::test]
    async fn pause_navigation_fails_for_unknown_session() {
        let handler = PauseNavigationHandler::new(repo());
        let result = handler
            .handle(PauseNavigationCommand {
                session_id: uuid::Uuid::new_v4(),
            })
            .await;
        assert!(result.is_err());
    }

    // ── ResumeNavigationHandler ──────────────────────────────────────────────

    #[tokio::test]
    async fn resume_navigation_restores_active_status() {
        let nav_repo = repo();
        let session = {
            let h = StartNavigationHandler::new(
                Arc::new(FixedRouteService(make_route())),
                nav_repo.clone(),
                device_comm(),
                event_bus(),
            );
            h.handle(StartNavigationCommand {
                waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)],
                current_position: pos(40.71, -74.01),
                device_id: None,
            })
            .await
            .unwrap()
        };
        PauseNavigationHandler::new(nav_repo.clone())
            .handle(PauseNavigationCommand {
                session_id: session.id,
            })
            .await
            .unwrap();
        ResumeNavigationHandler::new(nav_repo.clone())
            .handle(ResumeNavigationCommand {
                session_id: session.id,
            })
            .await
            .unwrap();

        let loaded = nav_repo.load_session(session.id).await.unwrap().unwrap();
        assert_eq!(loaded.status, NavigationStatus::Active);
    }

    // ── StopNavigationHandler ────────────────────────────────────────────────

    #[tokio::test]
    async fn stop_navigation_completed() {
        let nav_repo = repo();
        let session = {
            let h = StartNavigationHandler::new(
                Arc::new(FixedRouteService(make_route())),
                nav_repo.clone(),
                device_comm(),
                event_bus(),
            );
            h.handle(StartNavigationCommand {
                waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)],
                current_position: pos(40.71, -74.01),
                device_id: None,
            })
            .await
            .unwrap()
        };
        StopNavigationHandler::new(nav_repo.clone(), event_bus())
            .handle(StopNavigationCommand {
                session_id: session.id,
                completed: true,
            })
            .await
            .unwrap();
        let loaded = nav_repo.load_session(session.id).await.unwrap().unwrap();
        assert_eq!(loaded.status, NavigationStatus::Completed);
    }

    #[tokio::test]
    async fn stop_navigation_cancelled() {
        let nav_repo = repo();
        let session = {
            let h = StartNavigationHandler::new(
                Arc::new(FixedRouteService(make_route())),
                nav_repo.clone(),
                device_comm(),
                event_bus(),
            );
            h.handle(StartNavigationCommand {
                waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)],
                current_position: pos(40.71, -74.01),
                device_id: None,
            })
            .await
            .unwrap()
        };
        StopNavigationHandler::new(nav_repo.clone(), event_bus())
            .handle(StopNavigationCommand {
                session_id: session.id,
                completed: false,
            })
            .await
            .unwrap();
        let loaded = nav_repo.load_session(session.id).await.unwrap().unwrap();
        assert_eq!(loaded.status, NavigationStatus::Cancelled);
    }

    // ── UpdatePositionHandler ────────────────────────────────────────────────

    #[tokio::test]
    async fn update_position_persists_new_position() {
        let nav_repo = repo();
        let session = {
            let h = StartNavigationHandler::new(
                Arc::new(FixedRouteService(make_route())),
                nav_repo.clone(),
                device_comm(),
                event_bus(),
            );
            h.handle(StartNavigationCommand {
                waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)],
                current_position: pos(40.71, -74.01),
                device_id: None,
            })
            .await
            .unwrap()
        };
        let new_pos = pos(40.73, -74.00);
        UpdatePositionHandler::new(nav_repo.clone(), event_bus())
            .handle(UpdatePositionCommand {
                session_id: session.id,
                position: new_pos,
            })
            .await
            .unwrap();
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
            let h = StartNavigationHandler::new(
                Arc::new(FixedRouteService(make_route())),
                nav_repo.clone(),
                device_comm(),
                event_bus(),
            );
            h.handle(StartNavigationCommand {
                waypoints: vec![pos(40.71, -74.01), pos(40.76, -73.99)],
                current_position: pos(40.71, -74.01),
                device_id: None,
            })
            .await
            .unwrap()
        };
        let found = GetActiveSessionHandler::new(nav_repo)
            .handle(GetActiveSessionQuery {})
            .await
            .unwrap();
        assert_eq!(found.unwrap().id, session.id);
    }

    // ── GeocodeHandler / ReverseGeocodeHandler ───────────────────────────────

    #[tokio::test]
    async fn geocode_handler_returns_results() {
        let handler = GeocodeHandler::new(Arc::new(FixedGeocodingService));
        let result = handler
            .handle(GeocodeQuery {
                address: "London".into(),
                limit: None,
            })
            .await
            .unwrap();
        assert_eq!(result.len(), 1);
        assert!((result[0].position.latitude - 51.5).abs() < 0.01);
    }

    #[tokio::test]
    async fn reverse_geocode_handler_returns_address() {
        let handler = ReverseGeocodeHandler::new(Arc::new(FixedGeocodingService));
        let result = handler
            .handle(ReverseGeocodeQuery {
                position: pos(51.5, -0.12),
            })
            .await
            .unwrap();
        assert!(result.contains("London"));
    }
}
