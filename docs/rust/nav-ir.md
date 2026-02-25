# Nav-IR (Navigation Intermediate Representation)

**Version:** 0.1  
**Nav-IR** is a canonical, engine-agnostic route format used in nav-e. It normalizes routes from different sources (OSRM, GPX, custom APIs) into a single contract that the core and device communication layer use.

## Purpose

Nav-IR is designed to:

- **Normalize** routes from multiple ecosystems (GPX, routing APIs, custom formats)
- **Preserve route intent** (fixed vs recalculatable segments)
- **Support fixed and recalculatable segments**
- **Enable deterministic execution** on embedded devices (e.g. watches)
- **Remain independent** of routing engines and map tile systems
- **Provide forward compatibility** for future custom routing engines
- **Provide a single pipeline** for sending routes to devices: Nav-IR → RouteBlob

Nav-IR is not a routing engine and not a UI model. It is a runtime-ready navigation contract.

## Design principles

| Principle | Description |
|-----------|-------------|
| **Engine-agnostic** | No dependency on OSRM, device_comm, or nav_core; transport-agnostic |
| **Intent-preserving** | Segment intent (Fixed, Recalculatable, Advisory) drives runtime behavior |
| **Segment-oriented** | Routes are made of segments (mixed-mode, multi-day, recalculation boundaries) |
| **Execution-friendly** | Geometry, waypoints, and policies are sufficient for device execution |
| **Extensible and versioned** | `schema_version` allows evolution without breaking consumers |
| **Deterministic once compiled** | Compiled form (e.g. RouteBlob) is deterministic for device execution |

## Crate and dependencies

- **Crate:** `native/nav_ir`
- **Dependencies:** `serde`, `chrono`, `uuid`, `polyline` (for encoding/decoding)
- **No dependency on** `device_comm` or `nav_core`

```
nav_ir (canonical format)
    ↑
nav_core (orchestration, session, Nav-IR → RouteBlob)
    ↑
nav_e_ffi (FFI to Flutter)
```

---

## Type specification

Rust types live in `native/nav_ir/src/types.rs`. All types are `Serialize` / `Deserialize` for JSON and storage.

### 1. Route (top-level)

```
Route {
    schema_version: u16,
    id: RouteId,
    metadata: RouteMetadata,
    segments: Vec<RouteSegment>,
    policies: RoutePolicies,
}
```

### 2. RouteMetadata

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

### 3. RouteSegment

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

### 4. SegmentIntent

```
enum SegmentIntent {
    FixedGeometry,
    Recalculatable,
    AdvisoryTrack,
}
```

**Semantics:** Intent determines allowable runtime behavior.

### 5. RouteGeometry

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

### 6. Waypoints

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

### 7. Instructions (optional)

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

### 8. SegmentConstraints

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

### 9. RoutePolicies

```
RoutePolicies {
    off_route_behavior: OffRouteBehavior,  // Recalculate | SnapToRoute | AlertOnly
    snapping_mode: SnappingMode,           // Strict | Relaxed | Off
}
```

### 10. Identifiers and coordinate

- **RouteId**, **SegmentId**, **WaypointId**, **InstructionId** – UUID wrappers
- **Coordinate** – `latitude: f64`, `longitude: f64`
- **EncodedPolyline** – newtype around `String`
- **BoundingBox** – `min_lat`, `min_lon`, `max_lat`, `max_lon`

### 11. Execution state (separate from Nav-IR)

Runtime progress (e.g. current position, visited waypoints, ETA) must be stored separately. Nav-IR describes the route contract; execution state is maintained by the core or device.

---

## Role in the stack

1. **Route calculation (OSRM)** – The OSRM adapter in nav_core builds a `nav_ir::Route` (single segment, `Recalculatable`, `SnappedToGraph`) and returns it.
2. **Session** – `NavigationSession` in nav_core holds a `nav_ir::Route`.
3. **Device send** – The only path to a device is **Nav-IR → RouteBlob** in `nav_core/src/infrastructure/nav_ir_to_proto.rs` (`nav_ir_route_to_route_blob`). The protobuf adapter and `prepare_route_message` (JSON → Nav-IR → RouteBlob) use this.
4. **DTO / FFI** – Route DTOs for Flutter are built from `nav_ir::Route` via `route_to_dto` in `api/dto.rs`.

## Testing

- **Unit tests:** `cargo test -p nav_ir` (Nav-IR crate); `cargo test -p nav_core` (includes Nav-IR → RouteBlob and DTO conversions).
- **Manual / E2E:** Call `prepare_route_message` with valid route JSON from the app or FFI tests.

See [Device Communication – Testing Nav-IR](../guides/device-communication.md#testing-nav-ir) for full steps.

## Related docs

- **[Rust overview](overview.md)** – Crates and layering
- **[Device communication](../guides/device-communication.md)** – Sending routes to devices (Nav-IR → RouteBlob pipeline)
