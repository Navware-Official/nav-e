# Nav-IR schema

Field-level type definitions and invariants. Rust types live in `native/nav_ir/src/types.rs`. All types are `Serialize` / `Deserialize` for JSON and storage.

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

**Invariants:** `schema_version` must match a supported version (currently 1). A valid route should have at least one segment for device send.

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
}
```

**Semantics:** Metadata is informational only and must not affect execution logic.

## 3. RouteSegment

```
RouteSegment {
    id: SegmentId,
    intent: SegmentIntent,
    geometry: RouteGeometry,
    waypoints: Vec<Waypoint>,
    instructions: Vec<Instruction>,
    constraints: SegmentConstraints,
}
```

**Semantics:** Segments allow mixed-mode routes, recalculation boundaries, and multi-day trips.

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
    polyline: EncodedPolyline,   // encoded string (e.g. Google polyline)
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

## 6. Waypoint

```
Waypoint {
    id: WaypointId,
    coordinate: Coordinate,
    kind: WaypointKind,
    radius_m: Option<f64>,
}

enum WaypointKind {
    Start,
    Stop,
    Via,
    Shaping,
    Poi,
    Fuel,
    Break,
}
```

## 7. Instruction (optional)

```
Instruction {
    id: InstructionId,
    coordinate: Coordinate,
    kind: InstructionKind,
    distance_to_next_m: Option<f64>,
    street_name: Option<String>,
}

enum InstructionKind {
    TurnLeft, TurnRight, Continue, Arrive, Depart, Merge, Roundabout,
}
```

**Semantics:** Instructions may be imported or generated.

## 8. SegmentConstraints

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

## 9. RoutePolicies

```
RoutePolicies {
    off_route_behavior: OffRouteBehavior,  // Recalculate | SnapToRoute | AlertOnly
    snapping_mode: SnappingMode,           // Strict | Relaxed | Off
}
```

## 10. Identifiers and coordinate

- **RouteId**, **SegmentId**, **WaypointId**, **InstructionId** – UUID wrappers (e.g. string representation in JSON).
- **Coordinate** – `latitude: f64`, `longitude: f64`.
- **EncodedPolyline** – Newtype around `String`; use a standard encoding (e.g. Google polyline).
- **BoundingBox** – `min_lat`, `min_lon`, `max_lat`, `max_lon` (f64).

## 11. Execution state (separate from Nav-IR)

Runtime progress (e.g. current position, visited waypoints, ETA) must be stored separately. Nav-IR describes the route contract; execution state is maintained by the core or device.
