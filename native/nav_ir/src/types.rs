//! Nav-IR type definitions. See docs/nav-ir/README.md and docs/nav-ir/schema.md for the full specification.

use std::collections::HashMap;

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

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct LegId(pub Uuid);

impl LegId {
    pub fn new() -> Self {
        LegId(Uuid::new_v4())
    }
}

impl Default for LegId {
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

/// Provenance for imported routes (v2).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportSource {
    /// e.g. "gpx", "osrm", "valhalla"
    pub format: String,
    #[serde(default)]
    pub creator: Option<String>,
    pub imported_at: DateTime<Utc>,
    #[serde(default)]
    pub original_name: Option<String>,
    #[serde(default)]
    pub extras: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RouteMetadata {
    pub name: String,
    pub description: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub total_distance_m: Option<f64>,
    pub estimated_duration_s: Option<u64>,
    pub tags: Vec<String>,
    #[serde(default)]
    pub source: Option<ImportSource>,
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

// --- GeometryRef (v2) ---

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum GeometryRefKind {
    VertexIndex,
    SegmentFraction,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeometryRef {
    pub kind: GeometryRefKind,
    #[serde(default)]
    pub vertex_index: Option<u32>,
    #[serde(default)]
    pub seg_start_index: Option<u32>,
    #[serde(default)]
    pub fraction: Option<f32>,
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

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum WaypointRole {
    Announce,
    Shape,
    Poi,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum WaypointCategory {
    Start,
    End,
    Via,
    Fuel,
    Break,
    Info,
    Custom,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Waypoint {
    pub id: WaypointId,
    pub coordinate: Coordinate,
    pub kind: WaypointKind,
    pub radius_m: Option<f64>,
    #[serde(default)]
    pub name: Option<String>,
    /// Optional description (e.g. from GPX &lt;desc&gt; on rtept).
    #[serde(default)]
    pub description: Option<String>,
    #[serde(default)]
    pub role: Option<WaypointRole>,
    #[serde(default)]
    pub category: Option<WaypointCategory>,
    #[serde(default)]
    pub geometry_ref: Option<GeometryRef>,
}

impl Waypoint {
    /// Builder-style setter for optional name.
    pub fn with_name(mut self, name: impl Into<String>) -> Self {
        self.name = Some(name.into());
        self
    }
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
    #[serde(default)]
    pub coordinate: Option<Coordinate>,
    #[serde(default)]
    pub geometry_ref: Option<GeometryRef>,
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

// --- Leg (v2) ---

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct VertexRange {
    pub start: u32,
    pub end: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Leg {
    pub id: LegId,
    pub from: WaypointId,
    pub to: WaypointId,
    pub vertex_range: VertexRange,
    pub distance_m: Option<f64>,
    pub duration_s: Option<u64>,
}

// --- RouteSegment ---

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RouteSegment {
    pub id: SegmentId,
    pub intent: SegmentIntent,
    pub geometry: RouteGeometry,
    pub waypoints: Vec<Waypoint>,
    #[serde(default)]
    pub legs: Vec<Leg>,
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
    InstructionMissingCoordinateAndGeometryRef {
        segment_index: usize,
        instruction_index: usize,
    },
    GeometryRefInvalid {
        segment_index: usize,
        message: String,
    },
    LegVertexRangeInvalid {
        segment_index: usize,
        leg_index: usize,
    },
    LegWaypointNotInSegment {
        segment_index: usize,
        leg_index: usize,
    },
    LegsNotMonotonic { segment_index: usize },
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
            ValidationError::InstructionMissingCoordinateAndGeometryRef {
                segment_index,
                instruction_index,
            } => write!(
                f,
                "segment {} instruction {} must have coordinate or geometry_ref",
                segment_index, instruction_index
            ),
            ValidationError::GeometryRefInvalid {
                segment_index,
                message,
            } => write!(f, "segment {} geometry_ref invalid: {}", segment_index, message),
            ValidationError::LegVertexRangeInvalid {
                segment_index,
                leg_index,
            } => write!(
                f,
                "segment {} leg {} vertex_range must have start <= end",
                segment_index, leg_index
            ),
            ValidationError::LegWaypointNotInSegment {
                segment_index,
                leg_index,
            } => write!(
                f,
                "segment {} leg {} from/to waypoint IDs must exist in segment waypoints",
                segment_index, leg_index
            ),
            ValidationError::LegsNotMonotonic { segment_index } => write!(
                f,
                "segment {} legs must be monotonic (ordered vertex ranges)",
                segment_index
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

fn validate_geometry_ref(
    segment_index: usize,
    r: &GeometryRef,
) -> Result<(), ValidationError> {
    match r.kind {
        GeometryRefKind::VertexIndex => {
            if r.vertex_index.is_none() {
                return Err(ValidationError::GeometryRefInvalid {
                    segment_index,
                    message: "VertexIndex requires vertex_index".to_string(),
                });
            }
        }
        GeometryRefKind::SegmentFraction => {
            if r.seg_start_index.is_none() || r.fraction.is_none() {
                return Err(ValidationError::GeometryRefInvalid {
                    segment_index,
                    message: "SegmentFraction requires seg_start_index and fraction".to_string(),
                });
            }
            let f = r.fraction.unwrap();
            if !(0.0..=1.0).contains(&f) {
                return Err(ValidationError::GeometryRefInvalid {
                    segment_index,
                    message: format!("fraction must be in [0,1], got {}", f),
                });
            }
        }
    }
    Ok(())
}

impl Route {
    pub const CURRENT_SCHEMA_VERSION: u16 = 2;

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
                if let Some(ref gr) = wp.geometry_ref {
                    validate_geometry_ref(idx, gr)?;
                }
            }
            for (inst_idx, inst) in seg.instructions.iter().enumerate() {
                if inst.coordinate.is_none() && inst.geometry_ref.is_none() {
                    return Err(ValidationError::InstructionMissingCoordinateAndGeometryRef {
                        segment_index: idx,
                        instruction_index: inst_idx,
                    });
                }
                if let Some(ref coord) = inst.coordinate {
                    validate_coordinate(coord.latitude, coord.longitude)?;
                }
                if let Some(ref gr) = inst.geometry_ref {
                    validate_geometry_ref(idx, gr)?;
                }
            }
            let wp_ids: std::collections::HashSet<_> =
                seg.waypoints.iter().map(|w| w.id).collect();
            for (leg_idx, leg) in seg.legs.iter().enumerate() {
                if leg.vertex_range.start > leg.vertex_range.end {
                    return Err(ValidationError::LegVertexRangeInvalid {
                        segment_index: idx,
                        leg_index: leg_idx,
                    });
                }
                if !wp_ids.contains(&leg.from) || !wp_ids.contains(&leg.to) {
                    return Err(ValidationError::LegWaypointNotInSegment {
                        segment_index: idx,
                        leg_index: leg_idx,
                    });
                }
            }
            let mut prev_end: Option<u32> = None;
            for leg in &seg.legs {
                if let Some(pe) = prev_end {
                    if leg.vertex_range.start < pe {
                        return Err(ValidationError::LegsNotMonotonic {
                            segment_index: idx,
                        });
                    }
                }
                prev_end = Some(leg.vertex_range.end);
            }
        }
        Ok(())
    }
}
