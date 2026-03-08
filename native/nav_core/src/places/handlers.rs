// Places application service — handles all place, trip, and saved-route use cases.
use anyhow::{Context, Result};
use chrono::Utc;
use geo_types::Coord;

use crate::places::commands::*;
use crate::places::queries::*;
use crate::navigation::domain::ports::Repository;
use crate::infrastructure::database::{
    SavedPlaceEntity, SavedPlacesRepository, SavedRouteEntity, SavedRoutesRepository, TripEntity,
    TripsRepository,
};

/// Handles all use cases for saved places, trips, and saved routes.
///
/// Constructed once in [`AppContext`] and held for the lifetime of the app.
/// Each repo is cheaply cloneable (`Arc<Mutex<Connection>>` inside).
pub struct PlacesHandlers {
    places_repo: SavedPlacesRepository,
    trips_repo: TripsRepository,
    routes_repo: SavedRoutesRepository,
}

impl PlacesHandlers {
    pub fn new(
        places_repo: SavedPlacesRepository,
        trips_repo: TripsRepository,
        routes_repo: SavedRoutesRepository,
    ) -> Self {
        Self {
            places_repo,
            trips_repo,
            routes_repo,
        }
    }

    // ── Saved Places ──────────────────────────────────────────────────────────

    pub fn get_all_places(&self, _: GetAllPlacesQuery) -> Result<Vec<SavedPlaceEntity>> {
        self.places_repo.get_all()
    }

    pub fn get_place_by_id(&self, q: GetPlaceByIdQuery) -> Result<Option<SavedPlaceEntity>> {
        self.places_repo.get_by_id(q.id)
    }

    pub fn save_place(&self, cmd: SavePlaceCommand) -> Result<i64> {
        let entity = SavedPlaceEntity {
            id: None,
            type_id: cmd.type_id,
            source: cmd.source.unwrap_or_else(|| "manual".to_string()),
            remote_id: cmd.remote_id,
            name: cmd.name,
            address: cmd.address,
            lat: cmd.lat,
            lon: cmd.lon,
            created_at: Utc::now().timestamp_millis(),
        };
        self.places_repo.insert(entity)
    }

    pub fn delete_place(&self, cmd: DeletePlaceCommand) -> Result<()> {
        self.places_repo.delete(cmd.id)
    }

    // ── Trips ─────────────────────────────────────────────────────────────────

    pub fn get_all_trips(&self, _: GetAllTripsQuery) -> Result<Vec<TripEntity>> {
        self.trips_repo.get_all()
    }

    pub fn get_trip_by_id(&self, q: GetTripByIdQuery) -> Result<Option<TripEntity>> {
        self.trips_repo.get_by_id(q.id)
    }

    pub fn save_trip(&self, cmd: SaveTripCommand) -> Result<i64> {
        let entity = TripEntity {
            id: None,
            distance_m: cmd.distance_m,
            duration_seconds: cmd.duration_seconds,
            started_at: cmd.started_at,
            completed_at: cmd.completed_at,
            status: cmd.status,
            destination_label: cmd.destination_label,
            route_id: cmd.route_id,
            polyline_encoded: cmd.polyline_encoded,
            created_at: cmd.completed_at,
        };
        self.trips_repo.insert(entity)
    }

    pub fn delete_trip(&self, cmd: DeleteTripCommand) -> Result<()> {
        self.trips_repo.delete(cmd.id)
    }

    // ── Saved Routes ──────────────────────────────────────────────────────────

    pub fn get_all_saved_routes(&self, _: GetAllSavedRoutesQuery) -> Result<Vec<SavedRouteEntity>> {
        self.routes_repo.get_all()
    }

    pub fn get_saved_route_by_id(
        &self,
        q: GetSavedRouteByIdQuery,
    ) -> Result<Option<SavedRouteEntity>> {
        self.routes_repo.get_by_id(q.id)
    }

    /// Parse GPX bytes into a Nav-IR route without persisting (preview flow).
    pub fn parse_route_from_gpx(&self, q: ParseRouteFromGpxQuery) -> Result<nav_ir::Route> {
        nav_ir::normalize_gpx(&q.bytes).map_err(|e| anyhow::anyhow!("{}", e))
    }

    /// Validate and persist a pre-parsed Nav-IR JSON string. Returns the saved row.
    pub fn save_route_from_json(&self, cmd: SaveRouteFromJsonCommand) -> Result<SavedRouteEntity> {
        let route: nav_ir::Route = serde_json::from_str(&cmd.route_json)
            .map_err(|e| anyhow::anyhow!("Invalid route JSON: {}", e))?;
        route.validate().map_err(|e| anyhow::anyhow!("{}", e))?;
        let entity = SavedRouteEntity {
            id: None,
            name: route.metadata.name.clone(),
            route_json: cmd.route_json,
            source: cmd.source,
            created_at: Utc::now().timestamp(),
        };
        let id = self.routes_repo.insert(entity)?;
        self.routes_repo
            .get_by_id(id)?
            .context("Saved route not found after insert")
    }

    /// Parse GPX bytes, persist the route, and return the saved row.
    pub fn import_route_from_gpx(
        &self,
        cmd: ImportRouteFromGpxCommand,
    ) -> Result<SavedRouteEntity> {
        let route =
            nav_ir::normalize_gpx(&cmd.bytes).map_err(|e| anyhow::anyhow!("{}", e))?;
        let route_json = serde_json::to_string(&route)?;
        let entity = SavedRouteEntity {
            id: None,
            name: route.metadata.name.clone(),
            route_json,
            source: "gpx".to_string(),
            created_at: Utc::now().timestamp(),
        };
        let id = self.routes_repo.insert(entity)?;
        self.routes_repo
            .get_by_id(id)?
            .context("Saved route not found after import")
    }

    /// Build a Nav-IR route from plan waypoints, persist it, and return the new row id.
    pub fn save_route_from_plan(&self, cmd: SaveRouteFromPlanCommand) -> Result<i64> {
        if cmd.waypoints.len() < 2 {
            anyhow::bail!("Need at least two waypoints (Start and Stop)");
        }
        let polyline_str = match cmd.polyline_encoded.as_deref() {
            Some(s) if !s.is_empty() => s.to_string(),
            _ => {
                let coords: Vec<Coord<f64>> = cmd
                    .waypoints
                    .iter()
                    .map(|(lat, lon)| Coord { x: *lon, y: *lat })
                    .collect();
                polyline::encode_coordinates(coords, 5)
                    .map_err(|e| anyhow::anyhow!("{}", e))?
            }
        };
        let mut route =
            nav_ir::normalize_custom(&cmd.waypoints, &polyline_str, cmd.distance_m, cmd.duration_s)
                .map_err(|e| anyhow::anyhow!("{}", e))?;
        route.metadata.name = cmd.name;
        let route_json = serde_json::to_string(&route)?;
        let entity = SavedRouteEntity {
            id: None,
            name: route.metadata.name.clone(),
            route_json,
            source: "plan".to_string(),
            created_at: Utc::now().timestamp(),
        };
        self.routes_repo.insert(entity)
    }

    pub fn delete_saved_route(&self, cmd: DeleteSavedRouteCommand) -> Result<()> {
        self.routes_repo.delete(cmd.id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::migrations::{get_all_migrations, MigrationManager};
    use rusqlite::Connection;
    use std::sync::{Arc, Mutex};

    fn setup_db() -> Arc<Mutex<Connection>> {
        let conn = Arc::new(Mutex::new(Connection::open_in_memory().unwrap()));
        MigrationManager::new(Arc::clone(&conn))
            .migrate(&get_all_migrations())
            .unwrap();
        conn
    }

    fn handlers(db: Arc<Mutex<Connection>>) -> PlacesHandlers {
        PlacesHandlers::new(
            SavedPlacesRepository::new(Arc::clone(&db)),
            TripsRepository::new(Arc::clone(&db)),
            SavedRoutesRepository::new(Arc::clone(&db)),
        )
    }

    // ── Saved Places ──────────────────────────────────────────────────────────

    #[test]
    fn save_and_get_place() {
        let h = handlers(setup_db());
        let id = h
            .save_place(SavePlaceCommand {
                name: "Home".into(),
                address: Some("1 Main St".into()),
                lat: 51.5,
                lon: -0.12,
                source: None,
                type_id: None,
                remote_id: None,
            })
            .unwrap();
        let place = h
            .get_place_by_id(GetPlaceByIdQuery { id })
            .unwrap()
            .unwrap();
        assert_eq!(place.name, "Home");
        assert_eq!(place.source, "manual");
    }

    #[test]
    fn get_all_places_returns_inserted() {
        let h = handlers(setup_db());
        h.save_place(SavePlaceCommand {
            name: "A".into(),
            address: None,
            lat: 0.0,
            lon: 0.0,
            source: Some("import".into()),
            type_id: None,
            remote_id: None,
        })
        .unwrap();
        h.save_place(SavePlaceCommand {
            name: "B".into(),
            address: None,
            lat: 1.0,
            lon: 1.0,
            source: None,
            type_id: None,
            remote_id: None,
        })
        .unwrap();
        let all = h.get_all_places(GetAllPlacesQuery).unwrap();
        assert_eq!(all.len(), 2);
    }

    #[test]
    fn delete_place_removes_it() {
        let h = handlers(setup_db());
        let id = h
            .save_place(SavePlaceCommand {
                name: "Work".into(),
                address: None,
                lat: 51.5,
                lon: -0.1,
                source: None,
                type_id: None,
                remote_id: None,
            })
            .unwrap();
        h.delete_place(DeletePlaceCommand { id }).unwrap();
        assert!(h
            .get_place_by_id(GetPlaceByIdQuery { id })
            .unwrap()
            .is_none());
    }

    #[test]
    fn get_place_by_id_returns_none_for_missing() {
        let h = handlers(setup_db());
        assert!(h
            .get_place_by_id(GetPlaceByIdQuery { id: 999 })
            .unwrap()
            .is_none());
    }

    // ── Trips ─────────────────────────────────────────────────────────────────

    fn trip_cmd() -> SaveTripCommand {
        SaveTripCommand {
            distance_m: 5000.0,
            duration_seconds: 1200,
            started_at: 1_700_000_000_000,
            completed_at: 1_700_001_200_000,
            status: "completed".into(),
            destination_label: Some("Park".into()),
            route_id: None,
            polyline_encoded: None,
        }
    }

    #[test]
    fn save_and_get_trip() {
        let h = handlers(setup_db());
        let id = h.save_trip(trip_cmd()).unwrap();
        let trip = h.get_trip_by_id(GetTripByIdQuery { id }).unwrap().unwrap();
        assert_eq!(trip.status, "completed");
        assert!((trip.distance_m - 5000.0).abs() < f64::EPSILON);
    }

    #[test]
    fn get_all_trips_returns_all() {
        let h = handlers(setup_db());
        h.save_trip(trip_cmd()).unwrap();
        h.save_trip(trip_cmd()).unwrap();
        assert_eq!(h.get_all_trips(GetAllTripsQuery).unwrap().len(), 2);
    }

    #[test]
    fn delete_trip_removes_it() {
        let h = handlers(setup_db());
        let id = h.save_trip(trip_cmd()).unwrap();
        h.delete_trip(DeleteTripCommand { id }).unwrap();
        assert!(h.get_trip_by_id(GetTripByIdQuery { id }).unwrap().is_none());
    }

    // ── Saved Routes ──────────────────────────────────────────────────────────

    #[test]
    fn save_route_from_plan_two_waypoints() {
        let h = handlers(setup_db());
        let id = h
            .save_route_from_plan(SaveRouteFromPlanCommand {
                name: "Test Route".into(),
                waypoints: vec![(51.5, -0.12), (51.6, -0.10)],
                polyline_encoded: None,
                distance_m: Some(5000.0),
                duration_s: Some(600),
            })
            .unwrap();
        let route = h
            .get_saved_route_by_id(GetSavedRouteByIdQuery { id })
            .unwrap()
            .unwrap();
        assert_eq!(route.name, "Test Route");
        assert_eq!(route.source, "plan");
    }

    #[test]
    fn save_route_from_plan_rejects_single_waypoint() {
        let h = handlers(setup_db());
        let result = h.save_route_from_plan(SaveRouteFromPlanCommand {
            name: "Bad".into(),
            waypoints: vec![(51.5, -0.12)],
            polyline_encoded: None,
            distance_m: None,
            duration_s: None,
        });
        assert!(result.is_err());
    }

    #[test]
    fn get_all_saved_routes_returns_all() {
        let h = handlers(setup_db());
        h.save_route_from_plan(SaveRouteFromPlanCommand {
            name: "R1".into(),
            waypoints: vec![(0.0, 0.0), (1.0, 1.0)],
            polyline_encoded: None,
            distance_m: None,
            duration_s: None,
        })
        .unwrap();
        h.save_route_from_plan(SaveRouteFromPlanCommand {
            name: "R2".into(),
            waypoints: vec![(2.0, 2.0), (3.0, 3.0)],
            polyline_encoded: None,
            distance_m: None,
            duration_s: None,
        })
        .unwrap();
        assert_eq!(
            h.get_all_saved_routes(GetAllSavedRoutesQuery).unwrap().len(),
            2
        );
    }

    #[test]
    fn delete_saved_route_removes_it() {
        let h = handlers(setup_db());
        let id = h
            .save_route_from_plan(SaveRouteFromPlanCommand {
                name: "To Delete".into(),
                waypoints: vec![(0.0, 0.0), (1.0, 1.0)],
                polyline_encoded: None,
                distance_m: None,
                duration_s: None,
            })
            .unwrap();
        h.delete_saved_route(DeleteSavedRouteCommand { id }).unwrap();
        assert!(h
            .get_saved_route_by_id(GetSavedRouteByIdQuery { id })
            .unwrap()
            .is_none());
    }
}
