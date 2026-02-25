//! Nav-IR type definitions. See docs/nav-ir/README.md and docs/nav-ir/schema.md for the full specification.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// --- Ids ---

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct RouteId(pub Uuid);

impl RouteId {
    pub fn new() -> Self {
        RouteId(Uuid::new_v4())
    }
}

impl Default for RouteId {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct SegmentId(pub Uuid);

impl SegmentId {
    pub fn new() -> Self {
        SegmentId(Uuid::new_v4())
    }
}

impl Default for SegmentId {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct WaypointId(pub Uuid);

impl WaypointId {
    pub fn new() -> Self {
        WaypointId(Uuid::new_v4())
    }
}

impl Default for WaypointId {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct InstructionId(pub Uuid);

impl InstructionId {
    pub fn new() -> Self {
        InstructionId(Uuid::new_v4())
    }
}

impl Default for InstructionId {
    fn default() -> Self {
        Self::new()
    }
}

// --- Coordinate ---

#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Coordinate {
    pub latitude: f64,
    pub longitude: f64,
}

impl Coordinate {
    pub fn new(latitude: f64, longitude: f64) -> Self {
        Self {
            latitude,
            longitude,
        }
    }
}

// --- RouteMetadata ---

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RouteMetadata {
    pub name: String,
    pub description: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub total_distance_m: Option<f64>,
    pub estimated_duration_s: Option<u64>,
    pub tags: Vec<String>,
}

// --- SegmentIntent ---

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SegmentIntent {
    FixedGeometry,
    Recalculatable,
    AdvisoryTrack,
}

// --- Geometry ---

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EncodedPolyline(pub String);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum GeometrySource {
    ImportedExact,
    SnappedToGraph,
    Recalculated,
    Synthetic,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum GeometryConfidence {
    High,
    Medium,
    Low,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BoundingBox {
    pub min_lat: f64,
    pub min_lon: f64,
    pub max_lat: f64,
    pub max_lon: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RouteGeometry {
    pub polyline: EncodedPolyline,
    pub source: GeometrySource,
    pub confidence: GeometryConfidence,
    pub bounding_box: BoundingBox,
}

// --- Waypoint ---

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum WaypointKind {
    Start,
    Stop,
    Via,
    Shaping,
    Poi,
    Fuel,
    Break,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Waypoint {
    pub id: WaypointId,
    pub coordinate: Coordinate,
    pub kind: WaypointKind,
    pub radius_m: Option<f64>,
}

// --- Instruction ---

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum InstructionKind {
    TurnLeft,
    TurnRight,
    Continue,
    Arrive,
    Depart,
    Merge,
    Roundabout,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Instruction {
    pub id: InstructionId,
    pub coordinate: Coordinate,
    pub kind: InstructionKind,
    pub distance_to_next_m: Option<f64>,
    pub street_name: Option<String>,
}

// --- SegmentConstraints ---

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SegmentConstraints {
    pub allow_reroute: bool,
    pub avoid_highways: bool,
    pub avoid_tolls: bool,
    pub avoid_unpaved: bool,
    pub prefer_curvy: bool,
    pub max_speed_kmh: Option<u32>,
}

impl Default for SegmentConstraints {
    fn default() -> Self {
        Self {
            allow_reroute: true,
            avoid_highways: false,
            avoid_tolls: false,
            avoid_unpaved: false,
            prefer_curvy: false,
            max_speed_kmh: None,
        }
    }
}

// --- RoutePolicies ---

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum OffRouteBehavior {
    Recalculate,
    SnapToRoute,
    AlertOnly,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SnappingMode {
    Strict,
    Relaxed,
    Off,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RoutePolicies {
    pub off_route_behavior: OffRouteBehavior,
    pub snapping_mode: SnappingMode,
}

impl Default for RoutePolicies {
    fn default() -> Self {
        Self {
            off_route_behavior: OffRouteBehavior::Recalculate,
            snapping_mode: SnappingMode::Relaxed,
        }
    }
}

// --- RouteSegment ---

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RouteSegment {
    pub id: SegmentId,
    pub intent: SegmentIntent,
    pub geometry: RouteGeometry,
    pub waypoints: Vec<Waypoint>,
    pub instructions: Vec<Instruction>,
    pub constraints: SegmentConstraints,
}

// --- Route ---

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Route {
    pub schema_version: u16,
    pub id: RouteId,
    pub metadata: RouteMetadata,
    pub segments: Vec<RouteSegment>,
    pub policies: RoutePolicies,
}

impl Route {
    pub const CURRENT_SCHEMA_VERSION: u16 = 1;
}
