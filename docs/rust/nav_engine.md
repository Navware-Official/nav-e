# nav_engine

Runtime turn-by-turn navigation engine — pure logic, no I/O.

This crate takes a `nav_ir::Route` and a stream of GPS position updates and returns structured `NavigationState` snapshots describing the driver's progress. It handles step advancement, off-route detection, ETA calculation, polyline snapping, and constraint alerts with no async, no FFI, and no network dependencies.

## Architecture

`nav_engine` is a leaf crate in the dependency tree:

```
nav_e_ffi
  └── nav_core            ← session persistence, FFI wiring
        └── nav_engine    ← this crate (pure navigation logic)
              └── nav_ir  ← route format (Route, Coordinate, Instruction)
```

`nav_core` creates and drives a `NavigationEngine` instance per active session. The resulting `NavigationState` is serialized to JSON by `nav_e_ffi` before being returned to Dart.

## Quick start

```rust
use nav_engine::NavigationEngine;
use nav_ir::Coordinate;

// New session
let mut engine = NavigationEngine::new(route);

// Each GPS fix
let state = engine.update_position(
    Coordinate { latitude: 51.5074, longitude: -0.1278 },
    Some(13.8), // speed in m/s (optional)
);

println!("Step {}, {:.0}m to next turn", state.current_step, state.distance_to_next_m);
println!("Off route: {}", state.off_route.is_off_route);

// Resumed session (restore step + distance from persisted state)
let mut engine = NavigationEngine::new_with_state(route, saved_step, saved_distance_m);
```

## Public API

### `NavigationEngine`

The main entry point. Owns the decoded route polyline and all derived turn instructions.

```rust
/// Create a fresh engine starting at step 0.
pub fn new(route: Route) -> Self

/// Restore engine to a previously saved step and distance (session resume).
pub fn new_with_state(route: Route, current_step: usize, distance_traveled_m: f64) -> Self

/// Process a GPS fix and return the current navigation state.
/// speed_mps: optional GPS speed used for ETA; falls back to route duration then 40 km/h.
pub fn update_position(&mut self, pos: Coordinate, speed_mps: Option<f64>) -> NavigationState

/// Index of the current instruction step.
pub fn current_step(&self) -> usize

/// Total distance traveled so far (meters).
pub fn distance_traveled_m(&self) -> f64

/// All derived instructions for this route (useful for turn-list display).
pub fn instructions(&self) -> &[DerivedInstruction]
```

---

### `NavigationState`

The output of every `update_position` call.

```rust
pub struct NavigationState {
    /// Index into the instructions array for the step the driver is currently on.
    pub current_step: usize,
    /// Full instruction for the current step.
    pub current_instruction: DerivedInstruction,
    /// Next upcoming instruction, if any.
    pub next_instruction: Option<DerivedInstruction>,
    /// Distance from snapped position to the next instruction (meters).
    pub distance_to_next_m: f64,
    /// Total remaining distance to destination (meters).
    pub distance_remaining_m: f64,
    /// Estimated time to arrival (seconds).
    pub eta_seconds: u64,
    /// Off-route status.
    pub off_route: OffRouteStatus,
    /// Active constraint alerts (speed limits, highway/toll flags).
    pub constraint_alerts: Vec<ConstraintAlert>,
    /// GPS position projected onto the nearest polyline segment.
    pub snapped_position: Coordinate,
}
```

---

### `DerivedInstruction`

A single turn instruction derived from the route polyline.

```rust
pub struct DerivedInstruction {
    pub kind: DerivedInstructionKind,
    /// Index of the corresponding vertex in the decoded polyline.
    pub vertex_index: usize,
    /// Distance from this instruction to the next (meters).
    pub distance_to_next_m: f64,
    pub street_name: Option<String>,
}
```

---

### `DerivedInstructionKind`

```rust
pub enum DerivedInstructionKind {
    Depart,
    SharpLeft,
    TurnLeft,
    SlightLeft,
    Continue,
    SlightRight,
    TurnRight,
    SharpRight,
    Arrive,
}
```

Each variant implements `as_str() -> &'static str` for display.

**Turn angle thresholds** (bearing delta from previous segment):

| Delta | Kind |
|---|---|
| > 120° | `SharpRight` |
| ≥ 45° | `TurnRight` |
| ≥ 25° | `SlightRight` |
| −25° to 25° | `Continue` |
| −45° to −25° | `SlightLeft` |
| −120° to −45° | `TurnLeft` |
| ≤ −120° | `SharpLeft` |

---

### `OffRouteStatus`

```rust
pub struct OffRouteStatus {
    pub is_off_route: bool,
    /// Perpendicular distance from GPS position to the nearest polyline segment (meters).
    pub distance_from_route_m: f64,
    /// Re-routing policy sourced from the route's policies (e.g. Recalculate, Warn).
    pub behavior: nav_ir::OffRouteBehavior,
}
```

Off-route is triggered when `distance_from_route_m > 50.0`.

---

### `ConstraintAlert`

```rust
pub enum ConstraintAlert {
    SpeedLimit { max_kmh: u32 },
    AvoidHighway,
    AvoidToll,
}
```

Alerts are derived from the route's constraint metadata and included in every `NavigationState`.

## Step advancement

Steps advance automatically as the GPS position moves forward along the polyline. On each `update_position` call the engine finds the nearest polyline vertex to the current GPS fix, then advances `current_step` as long as the nearest vertex has passed the next instruction's `vertex_index`:

```
while current_step + 1 < instructions.len()
    && nearest_vertex >= instructions[current_step + 1].vertex_index
{
    current_step += 1;
}
```

This means the engine tolerates imprecise GPS — even if a position update is reported late, the correct step is recovered on the next fix.

## Off-route detection

`distance_to_polyline` projects the GPS position onto every segment of the decoded polyline and returns the minimum perpendicular distance, the index of the nearest vertex, and the actual projected (snapped) coordinate on that segment.

Off-route fires when that distance exceeds **50 m** (`OFF_ROUTE_THRESHOLD_M`). The `OffRouteBehavior` policy embedded in the route controls what the caller should do (recalculate, warn, etc.).

## ETA calculation

ETA priority order:

1. **Known GPS speed** (`speed_mps` argument) — `remaining_m / speed_mps`
2. **Route duration estimate** — scale `estimated_duration_s` proportionally by `remaining_m / total_distance_m`
3. **Fallback** — assume 40 km/h (11.111 m/s)

## Instruction derivation

`derive_instructions(vertices, existing)` builds the full instruction list:

1. Pre-existing `nav_ir::Instruction` items from the route are used directly.
2. Remaining polyline vertices with a bearing delta ≥ **25°** (`MIN_TURN_DEGREES`) generate a new `DerivedInstruction`.
3. Instructions closer than **30 m** (`MIN_INSTRUCTION_DISTANCE_M`) to the previous one are filtered out, keeping the higher-severity turn.
4. A `Depart` instruction is always prepended; an `Arrive` is always appended.

Turn severity used for filtering:

| Rank | Kinds |
|---|---|
| 5 (always kept) | `Depart`, `Arrive` |
| 4 | `SharpLeft`, `SharpRight` |
| 3 | `TurnLeft`, `TurnRight` |
| 2 | `SlightLeft`, `SlightRight` |
| 1 | `Continue` |

## Constants

| Constant | Value | Description |
|---|---|---|
| `OFF_ROUTE_THRESHOLD_M` | 50.0 m | Distance beyond which the driver is considered off-route |
| `MIN_TURN_DEGREES` | 25.0° | Minimum bearing delta to generate a turn instruction from a polyline vertex |
| `MIN_INSTRUCTION_DISTANCE_M` | 30.0 m | Minimum distance between consecutive instructions |
| Default ETA speed | 11.111 m/s | Fallback speed (40 km/h) when no GPS speed or route duration is available |
| Earth radius `R` | 6,371,000 m | Used in haversine distance calculations |

## Utility functions

These are public and can be used independently:

```rust
// derive_instructions module
pub fn haversine_distance(a: Coordinate, b: Coordinate) -> f64;
pub fn bearing(from: Coordinate, to: Coordinate) -> f64;
pub fn derive_instructions(vertices: &[Coordinate], existing: &[Instruction]) -> Vec<DerivedInstruction>;

// progress module
pub fn remaining_distance(vertices: &[Coordinate], from_vertex: usize) -> f64;
pub fn estimate_eta(remaining_m: f64, speed_mps: Option<f64>, route_duration_s: Option<u64>, total_distance_m: f64) -> u64;

// off_route module
pub fn distance_to_polyline(pos: Coordinate, vertices: &[Coordinate]) -> (f64, usize, Coordinate);
//                                                                          ^dist  ^vertex  ^snapped
```

## Dependencies

```toml
nav_ir   = { path = "../nav_ir" }
polyline = "0.11"   # Google encoded polyline decoding
geo-types = "0.7"   # Geographic coordinate types
```

No async runtime, no network, no FFI — safe to test in isolation.

## Crate layout

```
native/nav_engine/
├── Cargo.toml
└── src/
    ├── lib.rs                  # Public re-exports
    ├── engine.rs               # NavigationEngine — main state machine
    ├── types.rs                # NavigationState, DerivedInstruction, ConstraintAlert, OffRouteStatus
    ├── derive_instructions.rs  # Turn derivation, haversine, bearing
    ├── progress.rs             # Remaining distance, ETA
    └── off_route.rs            # Polyline distance + snapping
```
