// SQLite-backed NavigationRepository — survives app restarts
use crate::navigation::domain::{
    ports::NavigationRepository,
    session::{NavigationSession, NavigationStatus},
};
use crate::shared::value_objects::Position;
use anyhow::{Context, Result};
use async_trait::async_trait;
use chrono::TimeZone;
use rusqlite::{params, Connection};
use std::sync::{Arc, Mutex};
use uuid::Uuid;

pub struct SqliteNavigationRepository {
    db: Arc<Mutex<Connection>>,
}

impl SqliteNavigationRepository {
    pub fn new(db: Arc<Mutex<Connection>>) -> Self {
        Self { db }
    }
}

#[async_trait]
impl NavigationRepository for SqliteNavigationRepository {
    async fn save_session(&self, session: &NavigationSession) -> Result<()> {
        let route_json =
            serde_json::to_string(&session.route).context("Failed to serialize route")?;
        let status = status_to_str(session.status);
        let conn = self.db.lock().unwrap();
        conn.execute(
            "INSERT INTO navigation_sessions
                 (id, route_json, current_lat, current_lon, status, started_at, updated_at,
                  current_step_index, distance_traveled_m)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)
             ON CONFLICT(id) DO UPDATE SET
                 route_json          = excluded.route_json,
                 current_lat         = excluded.current_lat,
                 current_lon         = excluded.current_lon,
                 status              = excluded.status,
                 updated_at          = excluded.updated_at,
                 current_step_index  = excluded.current_step_index,
                 distance_traveled_m = excluded.distance_traveled_m",
            params![
                session.id.to_string(),
                route_json,
                session.current_position.latitude,
                session.current_position.longitude,
                status,
                session.started_at.timestamp(),
                session.updated_at.timestamp(),
                session.current_step_index as i64,
                session.distance_traveled_m,
            ],
        )
        .context("Failed to save navigation session")?;
        Ok(())
    }

    async fn load_session(&self, id: Uuid) -> Result<Option<NavigationSession>> {
        let conn = self.db.lock().unwrap();
        let result = conn.query_row(
            "SELECT id, route_json, current_lat, current_lon, status, started_at, updated_at,
                    COALESCE(current_step_index, 0), COALESCE(distance_traveled_m, 0.0)
             FROM navigation_sessions WHERE id = ?",
            [id.to_string()],
            extract_row,
        );
        match result {
            Ok(raw) => Ok(Some(deserialize_session(raw)?)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    async fn load_active_session(&self) -> Result<Option<NavigationSession>> {
        let conn = self.db.lock().unwrap();
        let result = conn.query_row(
            "SELECT id, route_json, current_lat, current_lon, status, started_at, updated_at,
                    COALESCE(current_step_index, 0), COALESCE(distance_traveled_m, 0.0)
             FROM navigation_sessions WHERE status = 'Active' LIMIT 1",
            [],
            extract_row,
        );
        match result {
            Ok(raw) => Ok(Some(deserialize_session(raw)?)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    async fn delete_session(&self, id: Uuid) -> Result<()> {
        let conn = self.db.lock().unwrap();
        conn.execute(
            "DELETE FROM navigation_sessions WHERE id = ?",
            [id.to_string()],
        )
        .context("Failed to delete navigation session")?;
        Ok(())
    }

    async fn get_session_stats(&self) -> Result<crate::navigation::domain::session::SessionStats> {
        let conn = self.db.lock().unwrap();
        let (total_distance_m, total_duration_seconds, session_count) = conn
            .query_row(
                "SELECT
                    COALESCE(SUM(COALESCE(distance_traveled_m, 0.0)), 0.0),
                    COALESCE(SUM(updated_at - started_at), 0),
                    COUNT(*)
                 FROM navigation_sessions
                 WHERE status != 'Cancelled'",
                [],
                |row| {
                    Ok((
                        row.get::<_, f64>(0)?,
                        row.get::<_, i64>(1)?,
                        row.get::<_, i64>(2)?,
                    ))
                },
            )
            .context("Failed to query session stats")?;
        Ok(crate::navigation::domain::session::SessionStats {
            total_distance_m,
            total_duration_seconds,
            session_count,
        })
    }
}

// ── helpers ──────────────────────────────────────────────────────────────────

type RawRow = (String, String, f64, f64, String, i64, i64, i64, f64);

fn extract_row(row: &rusqlite::Row) -> rusqlite::Result<RawRow> {
    Ok((
        row.get(0)?,
        row.get(1)?,
        row.get(2)?,
        row.get(3)?,
        row.get(4)?,
        row.get(5)?,
        row.get(6)?,
        row.get(7)?,
        row.get(8)?,
    ))
}

fn deserialize_session(
    (id_str, route_json, lat, lon, status_str, started_ts, updated_ts, step_idx, dist_m): RawRow,
) -> Result<NavigationSession> {
    let id = Uuid::parse_str(&id_str).context("Invalid session UUID")?;
    let route = serde_json::from_str(&route_json).context("Failed to deserialize route")?;
    let current_position = Position::new(lat, lon)?;
    let status = match status_str.as_str() {
        "Paused" => NavigationStatus::Paused,
        "Completed" => NavigationStatus::Completed,
        "Cancelled" => NavigationStatus::Cancelled,
        _ => NavigationStatus::Active,
    };
    let started_at = chrono::Utc
        .timestamp_opt(started_ts, 0)
        .single()
        .unwrap_or_else(chrono::Utc::now);
    let updated_at = chrono::Utc
        .timestamp_opt(updated_ts, 0)
        .single()
        .unwrap_or_else(chrono::Utc::now);

    Ok(NavigationSession {
        id,
        route,
        current_position,
        status,
        started_at,
        updated_at,
        current_step_index: step_idx.max(0) as usize,
        distance_traveled_m: dist_m,
    })
}

fn status_to_str(status: NavigationStatus) -> &'static str {
    match status {
        NavigationStatus::Active => "Active",
        NavigationStatus::Paused => "Paused",
        NavigationStatus::Completed => "Completed",
        NavigationStatus::Cancelled => "Cancelled",
    }
}

// ── tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use crate::migrations::{get_all_migrations, MigrationManager};
    use chrono::Utc;
    use nav_ir::*;

    fn setup_db() -> Arc<Mutex<Connection>> {
        let conn = Arc::new(Mutex::new(Connection::open_in_memory().unwrap()));
        let mgr = MigrationManager::new(Arc::clone(&conn));
        mgr.migrate(&get_all_migrations()).unwrap();
        conn
    }

    fn make_route() -> nav_ir::Route {
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

    fn make_session(status: NavigationStatus) -> NavigationSession {
        let mut s = NavigationSession::new(make_route(), Position::new(40.71, -74.01).unwrap());
        s.status = status;
        s
    }

    #[tokio::test]
    async fn save_and_load_session() {
        let repo = SqliteNavigationRepository::new(setup_db());
        let s = make_session(NavigationStatus::Active);
        let id = s.id;
        repo.save_session(&s).await.unwrap();
        let loaded = repo.load_session(id).await.unwrap();
        assert!(loaded.is_some());
        assert_eq!(loaded.unwrap().id, id);
    }

    #[tokio::test]
    async fn load_unknown_session_returns_none() {
        let repo = SqliteNavigationRepository::new(setup_db());
        assert!(repo.load_session(Uuid::new_v4()).await.unwrap().is_none());
    }

    #[tokio::test]
    async fn save_session_upserts_existing() {
        let repo = SqliteNavigationRepository::new(setup_db());
        let mut s = make_session(NavigationStatus::Active);
        let id = s.id;
        repo.save_session(&s).await.unwrap();
        s.status = NavigationStatus::Paused;
        repo.save_session(&s).await.unwrap();
        let loaded = repo.load_session(id).await.unwrap().unwrap();
        assert_eq!(loaded.status, NavigationStatus::Paused);
    }

    #[tokio::test]
    async fn delete_session_removes_it() {
        let repo = SqliteNavigationRepository::new(setup_db());
        let s = make_session(NavigationStatus::Active);
        let id = s.id;
        repo.save_session(&s).await.unwrap();
        repo.delete_session(id).await.unwrap();
        assert!(repo.load_session(id).await.unwrap().is_none());
    }

    #[tokio::test]
    async fn load_active_session_returns_active() {
        let repo = SqliteNavigationRepository::new(setup_db());
        let active = make_session(NavigationStatus::Active);
        let paused = make_session(NavigationStatus::Paused);
        repo.save_session(&active).await.unwrap();
        repo.save_session(&paused).await.unwrap();
        let found = repo.load_active_session().await.unwrap();
        assert_eq!(found.unwrap().id, active.id);
    }

    #[tokio::test]
    async fn load_active_session_returns_none_when_all_paused() {
        let repo = SqliteNavigationRepository::new(setup_db());
        repo.save_session(&make_session(NavigationStatus::Paused))
            .await
            .unwrap();
        assert!(repo.load_active_session().await.unwrap().is_none());
    }

    #[tokio::test]
    async fn session_status_round_trips() {
        let repo = SqliteNavigationRepository::new(setup_db());
        for status in [
            NavigationStatus::Active,
            NavigationStatus::Paused,
            NavigationStatus::Completed,
            NavigationStatus::Cancelled,
        ] {
            let s = make_session(status);
            let id = s.id;
            repo.save_session(&s).await.unwrap();
            let loaded = repo.load_session(id).await.unwrap().unwrap();
            assert_eq!(loaded.status, status);
        }
    }
}
