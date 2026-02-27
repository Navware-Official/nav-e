# Nav-IR (Navigation Intermediate Representation)

**Version:** 0.1

Nav-IR is a canonical, engine-agnostic route format used in nav-e. It normalizes routes from different sources (OSRM, GPX, custom APIs) into a single contract that the core and device communication layer use.

## What it is

Nav-IR is designed to:

- **Normalize** routes from multiple ecosystems (GPX, routing APIs, custom formats)
- **Preserve route intent** (fixed vs recalculatable segments)
- **Support fixed and recalculatable segments**
- **Enable deterministic execution** on embedded devices (e.g. watches)
- **Remain independent** of routing engines and map tile systems
- **Provide forward compatibility** for future custom routing engines
- **Provide a single pipeline** for sending routes to devices: Nav-IR → RouteBlob

Nav-IR is not a routing engine and not a UI model. It is a runtime-ready navigation contract.

**Design principles:** Engine-agnostic; intent-preserving (segment intent drives runtime behavior); segment-oriented (mixed-mode, multi-day, recalculation boundaries); execution-friendly; extensible and versioned via `schema_version`; deterministic once compiled (e.g. RouteBlob).

## How to implement

### Producing Nav-IR

The **nav_ir** crate provides normalization adapters in `nav_ir::adapters` (see `native/nav_ir/src/adapters/`):

- **OSRM:** `normalize_osrm(json: &str) -> Result<Route, String>` and `impl TryFrom<OsrmResponse> for Route`. Use the JSON from OSRM `route/v1/driving` with `overview=full&geometries=polyline`.
- **GPX:** `normalize_gpx(bytes: &[u8]) -> Result<Route, String>`. Parses GPX track or route; first track (or first route) becomes one Nav-IR segment (FixedGeometry, ImportedExact).
- **Custom:** `normalize_custom(waypoints, polyline_encoded, total_distance_m, estimated_duration_s) -> Result<Route, String>` for minimal input.
- **GraphHopper:** `normalize_graphhopper(json)` is a stub for later.

Conceptual mapping and guidelines:

- **Routing engines (e.g. OSRM):** [normalization/osrm.md](normalization/osrm.md)
- **File import (e.g. GPX):** [normalization/gpx.md](normalization/gpx.md)
- **Custom API or engine:** [normalization/custom-api.md](normalization/custom-api.md)

### Consuming Nav-IR

In nav-e, Nav-IR is used by:

- **nav_core** – Holds a route in `NavigationSession`; converts to RouteBlob for device send and to DTOs for Flutter.
- **Device send** – Single path: Nav-IR → RouteBlob in `nav_core` (see [Device Communication](../guides/device-communication.md)).

## Crate and stack

- **Crate:** `native/nav_ir`
- **Dependencies:** `serde`, `serde_json`, `chrono`, `uuid`, `polyline`, `geo-types`, `gpx`. No dependency on `device_comm` or `nav_core`.

```
nav_ir (canonical format)
    ↑
nav_core (orchestration, session, Nav-IR → RouteBlob)
    ↑
nav_e_ffi (FFI to Flutter)
```

## Documentation

- [Concepts](concepts.md) – Route, segment, waypoint, instruction, geometry model
- [Schema](schema.md) – Field-level type definitions and invariants
- [Versioning](versioning.md) – Compatibility rules and when to bump `schema_version`
- [Normalization](normalization/) – Mapping from OSRM, GPX, and custom APIs to Nav-IR
- [Examples](examples/) – Minimal and source-specific JSON samples

## Testing

- **Unit tests:** `cargo test -p nav_ir` (Nav-IR crate); `cargo test -p nav_core` (Nav-IR → RouteBlob and DTO conversions).
- **Manual / E2E:** Call `prepare_route_message` with valid route JSON from the app or FFI tests.

See [Device Communication – Testing Nav-IR](../guides/device-communication.md#testing-nav-ir) for full steps.
