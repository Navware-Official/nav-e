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

/// Validation error for Nav-IR Route invariants.
#[derive(Debug, Clone, PartialEq)]
pub enum ValidationError {
    UnsupportedSchemaVersion(u16),
    EmptySegments,
    SegmentMissingStartOrStop { segment_index: usize },
    InvalidBoundingBox { segment_index: usize },
    CoordinateOutOfRange { lat: f64, lon: f64 },
}

impl std::fmt::Display for ValidationError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ValidationError::UnsupportedSchemaVersion(v) => {
                write!(f, "unsupported schema_version: {} (supported: {})", v, Route::CURRENT_SCHEMA_VERSION)
            }
            ValidationError::EmptySegments => write!(f, "route must have at least one segment"),
            ValidationError::SegmentMissingStartOrStop { segment_index } => write!(
                f,
                "segment {} must have at least two waypoints with first Start and last Stop",
                segment_index
            ),
            ValidationError::InvalidBoundingBox { segment_index } => write!(
                f,
                "segment {} bounding_box must have min_lat <= max_lat and min_lon <= max_lon",
                segment_index
            ),
            ValidationError::CoordinateOutOfRange { lat, lon } => write!(
                f,
                "coordinate out of range: lat={} (must be -90..=90), lon={} (must be -180..=180)",
                lat, lon
            ),
        }
    }
}

impl std::error::Error for ValidationError {}

fn validate_coordinate(lat: f64, lon: f64) -> Result<(), ValidationError> {
    if !(-90.0..=90.0).contains(&lat) || !(-180.0..=180.0).contains(&lon) {
        return Err(ValidationError::CoordinateOutOfRange { lat, lon });
    }
    Ok(())
}

impl Route {
    pub const CURRENT_SCHEMA_VERSION: u16 = 1;

    /// Validates the route against Nav-IR invariants. Returns `Ok(())` if valid.
    pub fn validate(&self) -> Result<(), ValidationError> {
        if self.schema_version != Self::CURRENT_SCHEMA_VERSION {
            return Err(ValidationError::UnsupportedSchemaVersion(self.schema_version));
        }
        if self.segments.is_empty() {
            return Err(ValidationError::EmptySegments);
        }
        for (idx, seg) in self.segments.iter().enumerate() {
            if seg.waypoints.len() < 2 {
                return Err(ValidationError::SegmentMissingStartOrStop {
                    segment_index: idx,
                });
            }
            let first = &seg.waypoints[0];
            let last = seg.waypoints.last().unwrap();
            if first.kind != WaypointKind::Start || last.kind != WaypointKind::Stop {
                return Err(ValidationError::SegmentMissingStartOrStop {
                    segment_index: idx,
                });
            }
            let b = &seg.geometry.bounding_box;
            if b.min_lat > b.max_lat || b.min_lon > b.max_lon {
                return Err(ValidationError::InvalidBoundingBox {
                    segment_index: idx,
                });
            }
            for wp in &seg.waypoints {
                validate_coordinate(wp.coordinate.latitude, wp.coordinate.longitude)?;
            }
            for inst in &seg.instructions {
                validate_coordinate(inst.coordinate.latitude, inst.coordinate.longitude)?;
            }
        }
        Ok(())
    }
}
