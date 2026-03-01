# Nav-IR schema

Field-level type definitions and invariants. Rust types live in `native/nav_ir/src/types.rs`. All types are `Serialize` / `Deserialize` for JSON and storage.

**Schema version:** 2 (v2 adds ImportSource, Leg, GeometryRef, extended Waypoint/Instruction, and leg/geometry-ref validation).

## 1. Route (top-level)

```
Route {
    schema_version: u16,
    id: RouteId,
    metadata: RouteMetadata,
    segments: Vec<RouteSegment>,
    policies: RoutePolicies,
}
```

**Invariants:** `schema_version` must match a supported version (currently 2). A valid route should have at least one segment for device send.

## 2. RouteMetadata

```
RouteMetadata {
    name: String,
    description: Option<String>,
    created_at: DateTime,
    updated_at: DateTime,
    total_distance_m: Option<f64>,
    estimated_duration_s: Option<u64>,
    tags: Vec<String>,
    source: Option<ImportSource>,   // v2: provenance for imported routes
}
```

### ImportSource (v2)

```
ImportSource {
    format: String,           // e.g. "gpx", "osrm", "valhalla"
    creator: Option<String>,
    imported_at: DateTime,
    original_name: Option<String>,
    extras: Map<String, JsonValue>,  // vendor extensions
}
```

**Semantics:** Metadata is informational only and must not affect execution logic. `source` records where the route was imported from when applicable.

## 3. RouteSegment

```
RouteSegment {
    id: SegmentId,
    intent: SegmentIntent,
    geometry: RouteGeometry,
    waypoints: Vec<Waypoint>,
    legs: Vec<Leg>,            // v2: explicit leg ranges
    instructions: Vec<Instruction>,
    constraints: SegmentConstraints,
}
```

**Semantics:** Segments allow mixed-mode routes, recalculation boundaries, and multi-day trips. Legs (v2) define explicit from/to waypoints and vertex ranges along the segment polyline.

## 4. SegmentIntent

```
enum SegmentIntent {
    FixedGeometry,
    Recalculatable,
    AdvisoryTrack,
}
```

**Semantics:** Intent determines allowable runtime behavior (e.g. whether to recalculate or follow geometry).

## 5. RouteGeometry

```
RouteGeometry {
    polyline: EncodedPolyline,
    source: GeometrySource,
    confidence: GeometryConfidence,
    bounding_box: BoundingBox,
}

enum GeometrySource {
    ImportedExact,
    SnappedToGraph,
    Recalculated,
    Synthetic,
}

enum GeometryConfidence {
    High,
    Medium,
    Low,
}
```

**Semantics:** Geometry is authoritative only when explicitly marked as high confidence and imported exact.

## 6. Waypoint (v2)

```
Waypoint {
    id: WaypointId,
    coordinate: Coordinate,
    kind: WaypointKind,
    radius_m: Option<f64>,
    name: Option<String>,           // v2
    role: Option<WaypointRole>,     // v2
    category: Option<WaypointCategory>,  // v2
    geometry_ref: Option<GeometryRef>,   // v2
}

enum WaypointKind {
    Start, Stop, Via, Shaping, Poi, Fuel, Break,
}

enum WaypointRole {
    Announce, Shape, Poi,
}

enum WaypointCategory {
    Start, End, Via, Fuel, Break, Info, Custom,
}
```

## 7. GeometryRef (v2)

```
GeometryRef {
    kind: GeometryRefKind,
    vertex_index: Option<u32>,
    seg_start_index: Option<u32>,
    fraction: Option<f32>,
}

enum GeometryRefKind {
    VertexIndex,    // vertex_index must be set
    SegmentFraction,  // seg_start_index and fraction must be set; fraction in [0, 1]
}
```

**Rules:** VertexIndex requires `vertex_index`. SegmentFraction requires `seg_start_index` and `fraction`; `fraction` ∈ [0, 1].

## 8. Leg (v2)

```
Leg {
    id: LegId,
    from: WaypointId,
    to: WaypointId,
    vertex_range: VertexRange,   // { start: u32, end: u32 }
    distance_m: Option<f64>,
    duration_s: Option<u64>,
}
```

**Rules:** `vertex_range.start ≤ vertex_range.end`. All waypoint IDs must exist in the segment’s waypoints. Ranges must be within the decoded polyline vertex count. Legs must be monotonic (ordered, non-overlapping vertex ranges).

## 9. Instruction (v2)

```
Instruction {
    id: InstructionId,
    coordinate: Option<Coordinate>,   // v2: optional
    geometry_ref: Option<GeometryRef>,  // v2
    kind: InstructionKind,
    distance_to_next_m: Option<f64>,
    street_name: Option<String>,
}

enum InstructionKind {
    TurnLeft, TurnRight, Continue, Arrive, Depart, Merge, Roundabout,
}
```

**Rule:** At least one of `coordinate` or `geometry_ref` must be present.

**Semantics:** Instructions may be imported or generated. When only `geometry_ref` is set, the position is derived from the segment polyline.

## 10. SegmentConstraints

```
SegmentConstraints {
    allow_reroute: bool,
    avoid_highways: bool,
    avoid_tolls: bool,
    avoid_unpaved: bool,
    prefer_curvy: bool,
    max_speed_kmh: Option<u32>,
}
```

**Semantics:** Constraints inform routing engines but do not mandate behavior.

## 11. RoutePolicies

```
RoutePolicies {
    off_route_behavior: OffRouteBehavior,  // Recalculate | SnapToRoute | AlertOnly
    snapping_mode: SnappingMode,           // Strict | Relaxed | Off
}
```

## 12. Identifiers and coordinate

- **RouteId**, **SegmentId**, **WaypointId**, **InstructionId**, **LegId** (v2) – UUID wrappers (e.g. string representation in JSON).
- **Coordinate** – `latitude: f64`, `longitude: f64`.
- **EncodedPolyline** – Newtype around `String`; use a standard encoding (e.g. Google polyline).
- **BoundingBox** – `min_lat`, `min_lon`, `max_lat`, `max_lon` (f64).
- **VertexRange** (v2) – `start: u32`, `end: u32`.

## Validation

The `nav_ir` crate provides `Route::validate()` which checks the following invariants. Use it before converting to RouteBlob or persisting.

- **schema_version** – Must equal the supported version (currently 2). Unsupported versions yield `ValidationError::UnsupportedSchemaVersion`.
- **segments** – Non-empty (required for device send). Empty list yields `ValidationError::EmptySegments`.
- **Per segment:**
  - **waypoints** – At least two waypoints; the first must have `kind == Start`, the last must have `kind == Stop`. Otherwise `ValidationError::SegmentMissingStartOrStop`.
  - **bounding_box** – `min_lat <= max_lat` and `min_lon <= max_lon`. Otherwise `ValidationError::InvalidBoundingBox`.
  - **Coordinates** (in waypoints) – Latitude in `[-90, 90]`, longitude in `[-180, 180]`. Otherwise `ValidationError::CoordinateOutOfRange`.
  - **Waypoint geometry_ref** – If present, must match GeometryRefKind (VertexIndex or SegmentFraction rules). Otherwise `ValidationError::GeometryRefInvalid`.
  - **Instructions** – Each must have at least one of `coordinate` or `geometry_ref`. If `coordinate` is set, it is validated for range. If `geometry_ref` is set, it is validated per kind. Missing both yields `ValidationError::InstructionMissingCoordinateAndGeometryRef`.
  - **Legs** – For each leg: `vertex_range.start <= vertex_range.end` (`LegVertexRangeInvalid`); `from` and `to` must be in segment waypoints (`LegWaypointNotInSegment`); legs must be monotonic (`LegsNotMonotonic`).

In Rust: `route.validate()?` or `route.validate().map_err(|e| anyhow::anyhow!(e))?`. The `ValidationError` type is re-exported from the `nav_ir` crate.

## 13. Execution state (separate from Nav-IR)

Runtime progress (e.g. current position, visited waypoints, ETA) must be stored separately. Nav-IR describes the route contract; execution state is maintained by the core or device.
