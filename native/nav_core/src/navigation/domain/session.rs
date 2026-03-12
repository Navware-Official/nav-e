#![allow(dead_code)]
// Domain Entities - Core business objects with identity
use crate::shared::value_objects::*;
use chrono::{DateTime, Utc};
use nav_ir::Route as NavIrRoute;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Aggregated stats across all non-cancelled navigation sessions.
#[derive(Debug, Clone, Default)]
pub struct SessionStats {
    pub total_distance_m: f64,
    pub total_duration_seconds: i64,
    pub session_count: i64,
}

/// Represents an active navigation session. Route is Nav-IR (canonical format).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NavigationSession {
    pub id: Uuid,
    pub route: NavIrRoute,
    pub current_position: Position,
    pub status: NavigationStatus,
    pub started_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    /// Current instruction index (step) tracked by `nav_engine`.
    #[serde(default)]
    pub current_step_index: usize,
    /// Cumulative distance traveled in meters, updated by `nav_engine`.
    #[serde(default)]
    pub distance_traveled_m: f64,
}

impl NavigationSession {
    pub fn new(route: NavIrRoute, initial_position: Position) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            route,
            current_position: initial_position,
            status: NavigationStatus::Active,
            started_at: now,
            updated_at: now,
            current_step_index: 0,
            distance_traveled_m: 0.0,
        }
    }

    pub fn update_position(&mut self, position: Position) {
        self.current_position = position;
        self.updated_at = Utc::now();
    }

    pub fn complete(&mut self) {
        self.status = NavigationStatus::Completed;
        self.updated_at = Utc::now();
    }

    pub fn pause(&mut self) {
        self.status = NavigationStatus::Paused;
        self.updated_at = Utc::now();
    }

    pub fn resume(&mut self) {
        self.status = NavigationStatus::Active;
        self.updated_at = Utc::now();
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum NavigationStatus {
    Active,
    Paused,
    Completed,
    Cancelled,
}

/// Device connected to the navigation system

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Device {
    pub id: String,
    pub name: String,
    pub device_type: DeviceType,
    pub capabilities: DeviceCapabilities,
    pub battery_status: Option<BatteryInfo>,
    pub connected_at: DateTime<Utc>,
    pub last_seen: DateTime<Utc>,
}

impl Device {
    pub fn new(
        id: String,
        name: String,
        device_type: DeviceType,
        capabilities: DeviceCapabilities,
    ) -> Self {
        let now = Utc::now();
        Self {
            id,
            name,
            device_type,
            capabilities,
            battery_status: None,
            connected_at: now,
            last_seen: now,
        }
    }

    pub fn update_battery(&mut self, battery: BatteryInfo) {
        self.battery_status = Some(battery);
        self.last_seen = Utc::now();
    }

    pub fn update_last_seen(&mut self) {
        self.last_seen = Utc::now();
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DeviceType {
    WearOsWatch,
    CustomBleDevice,
    Smartphone,
}

/// Traffic alert affecting navigation

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrafficEvent {
    pub id: Uuid,
    pub position: Position,
    pub severity: TrafficSeverity,
    pub delay_seconds: u32,
    pub distance_ahead_meters: u32,
    pub description: String,
    pub reported_at: DateTime<Utc>,
}

impl TrafficEvent {
    pub fn new(
        position: Position,
        severity: TrafficSeverity,
        delay_seconds: u32,
        distance_ahead_meters: u32,
        description: String,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            position,
            severity,
            delay_seconds,
            distance_ahead_meters,
            description,
            reported_at: Utc::now(),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TrafficSeverity {
    Unknown,
    Low,
    Medium,
    High,
    Critical,
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_route() -> nav_ir::Route {
        use chrono::Utc;
        use nav_ir::*;
        Route {
            schema_version: Route::CURRENT_SCHEMA_VERSION,
            id: RouteId::new(),
            metadata: RouteMetadata {
                name: "test".into(),
                description: None,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                total_distance_m: Some(500.0),
                estimated_duration_s: Some(30),
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
                constraints: nav_ir::SegmentConstraints::default(),
            }],
            policies: nav_ir::RoutePolicies::default(),
        }
    }

    fn pos(lat: f64, lon: f64) -> Position {
        Position::new(lat, lon).unwrap()
    }

    // ── NavigationSession ────────────────────────────────────────────────────

    #[test]
    fn session_new_starts_active() {
        let s = NavigationSession::new(make_route(), pos(40.71, -74.01));
        assert_eq!(s.status, NavigationStatus::Active);
    }

    #[test]
    fn session_pause_resume() {
        let mut s = NavigationSession::new(make_route(), pos(40.71, -74.01));
        s.pause();
        assert_eq!(s.status, NavigationStatus::Paused);
        s.resume();
        assert_eq!(s.status, NavigationStatus::Active);
    }

    #[test]
    fn session_complete() {
        let mut s = NavigationSession::new(make_route(), pos(40.71, -74.01));
        s.complete();
        assert_eq!(s.status, NavigationStatus::Completed);
    }

    #[test]
    fn session_update_position() {
        let mut s = NavigationSession::new(make_route(), pos(40.71, -74.01));
        let new_pos = pos(40.72, -74.02);
        s.update_position(new_pos);
        assert_eq!(s.current_position, new_pos);
    }

    #[test]
    fn session_updated_at_changes_on_mutation() {
        let mut s = NavigationSession::new(make_route(), pos(40.71, -74.01));
        let before = s.updated_at;
        std::thread::sleep(std::time::Duration::from_millis(5));
        s.update_position(pos(40.72, -74.02));
        assert!(s.updated_at >= before);
    }

    // ── Device ───────────────────────────────────────────────────────────────

    #[test]
    fn device_new_no_battery() {
        let d = Device::new(
            "id1".into(),
            "Watch".into(),
            DeviceType::WearOsWatch,
            DeviceCapabilities::new(240, 240),
        );
        assert!(d.battery_status.is_none());
    }

    #[test]
    fn device_update_battery() {
        let mut d = Device::new(
            "id1".into(),
            "Watch".into(),
            DeviceType::WearOsWatch,
            DeviceCapabilities::new(240, 240),
        );
        d.update_battery(BatteryInfo::new(80, false));
        assert_eq!(d.battery_status.unwrap().percentage, 80);
    }
}
