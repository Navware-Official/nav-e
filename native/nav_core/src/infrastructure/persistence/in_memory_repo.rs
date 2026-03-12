// In-memory repository implementation for development/testing
use crate::navigation::domain::{ports::NavigationRepository, session::NavigationSession};
use anyhow::Result;
use async_trait::async_trait;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

pub struct InMemoryNavigationRepository {
    sessions: Arc<RwLock<HashMap<Uuid, NavigationSession>>>,
}

impl InMemoryNavigationRepository {
    pub fn new() -> Self {
        Self {
            sessions: Arc::new(RwLock::new(HashMap::new())),
        }
    }
}

impl Default for InMemoryNavigationRepository {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl NavigationRepository for InMemoryNavigationRepository {
    async fn save_session(&self, session: &NavigationSession) -> Result<()> {
        let mut sessions = self.sessions.write().await;
        sessions.insert(session.id, session.clone());
        Ok(())
    }

    async fn load_session(&self, id: Uuid) -> Result<Option<NavigationSession>> {
        let sessions = self.sessions.read().await;
        Ok(sessions.get(&id).cloned())
    }

    async fn load_active_session(&self) -> Result<Option<NavigationSession>> {
        let sessions = self.sessions.read().await;
        Ok(sessions
            .values()
            .find(|s| s.status == crate::navigation::domain::session::NavigationStatus::Active)
            .cloned())
    }

    async fn delete_session(&self, id: Uuid) -> Result<()> {
        let mut sessions = self.sessions.write().await;
        sessions.remove(&id);
        Ok(())
    }

    async fn get_session_stats(&self) -> Result<crate::navigation::domain::session::SessionStats> {
        use crate::navigation::domain::session::NavigationStatus;
        let sessions = self.sessions.read().await;
        let mut stats = crate::navigation::domain::session::SessionStats::default();
        for s in sessions.values() {
            if s.status == NavigationStatus::Cancelled {
                continue;
            }
            stats.total_distance_m += s.distance_traveled_m;
            stats.total_duration_seconds += (s.updated_at - s.started_at).num_seconds();
            stats.session_count += 1;
        }
        Ok(stats)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::navigation::domain::session::*;
    use crate::shared::value_objects::Position;

    fn make_session(status: NavigationStatus) -> NavigationSession {
        use chrono::Utc;
        use nav_ir::*;
        let route = Route {
            schema_version: Route::CURRENT_SCHEMA_VERSION,
            id: RouteId::new(),
            metadata: RouteMetadata {
                name: String::new(),
                description: None,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                total_distance_m: None,
                estimated_duration_s: None,
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
        };
        let mut s = NavigationSession::new(route, Position::new(40.71, -74.01).unwrap());
        s.status = status;
        s
    }

    #[tokio::test]
    async fn save_and_load_session() {
        let repo = InMemoryNavigationRepository::new();
        let s = make_session(NavigationStatus::Active);
        let id = s.id;
        repo.save_session(&s).await.unwrap();
        let loaded = repo.load_session(id).await.unwrap();
        assert!(loaded.is_some());
        assert_eq!(loaded.unwrap().id, id);
    }

    #[tokio::test]
    async fn load_unknown_session_returns_none() {
        let repo = InMemoryNavigationRepository::new();
        let result = repo.load_session(Uuid::new_v4()).await.unwrap();
        assert!(result.is_none());
    }

    #[tokio::test]
    async fn delete_session_removes_it() {
        let repo = InMemoryNavigationRepository::new();
        let s = make_session(NavigationStatus::Active);
        let id = s.id;
        repo.save_session(&s).await.unwrap();
        repo.delete_session(id).await.unwrap();
        assert!(repo.load_session(id).await.unwrap().is_none());
    }

    #[tokio::test]
    async fn load_active_session_returns_only_active() {
        let repo = InMemoryNavigationRepository::new();
        let active = make_session(NavigationStatus::Active);
        let paused = make_session(NavigationStatus::Paused);
        repo.save_session(&active).await.unwrap();
        repo.save_session(&paused).await.unwrap();
        let found = repo.load_active_session().await.unwrap();
        assert!(found.is_some());
        assert_eq!(found.unwrap().id, active.id);
    }

    #[tokio::test]
    async fn load_active_session_returns_none_when_all_paused() {
        let repo = InMemoryNavigationRepository::new();
        repo.save_session(&make_session(NavigationStatus::Paused))
            .await
            .unwrap();
        assert!(repo.load_active_session().await.unwrap().is_none());
    }

    #[tokio::test]
    async fn save_session_overwrites_existing() {
        let repo = InMemoryNavigationRepository::new();
        let mut s = make_session(NavigationStatus::Active);
        let id = s.id;
        repo.save_session(&s).await.unwrap();
        s.status = NavigationStatus::Paused;
        repo.save_session(&s).await.unwrap();
        let loaded = repo.load_session(id).await.unwrap().unwrap();
        assert_eq!(loaded.status, NavigationStatus::Paused);
    }
}
