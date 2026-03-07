# Nav Engine - Rust Core

A production-ready Rust navigation engine using **DDD/Hexagonal** architecture, exposed to Flutter via `flutter_rust_bridge` through a dedicated thin FFI wrapper crate.

## Crate Structure

```
native/
├── nav_core/            # Core navigation engine (internal)
│   └── src/
│       ├── api/           # Internal API layer (feature modules)
│       ├── domain/        # Domain layer (entities, value objects, ports, events)
│       ├── application/   # Application layer (handlers, commands, queries)
│       ├── infrastructure/# Infrastructure adapters (SQLite, device comm)
│       └── migrations/    # Database migrations
│
├── nav_route/           # Routing & geocoding adapters
│   └── src/
│       ├── osrm/          # OsrmRouteService (feature: osrm)
│       └── geocoding/     # NominatimGeocodingService (feature: nominatim)
│
└── nav_e_ffi/           # Thin FFI wrapper (public API)
    └── src/
        └── lib.rs         # Public functions forwarding to nav_core

flutter/lib/bridge/        # Generated Dart bindings
    ├── frb_generated.dart
    ├── frb_generated.io.dart
    └── lib.dart           # Public API (automatically generated)
```

## Core Engine Structure (`nav_core`)

```
native/nav_core/src/
├── api/                    # Internal API Layer (feature-based modules)
│   ├── mod.rs             # AppContext singleton and module coordination
│   ├── context.rs         # initialize_database(), get_context(), subscribe_navigation_events()
│   ├── dto.rs             # Data Transfer Objects & conversions
│   ├── helpers.rs         # JSON serialization helpers (query_json, command_async, block_on)
│   ├── geocoding.rs       # Geocoding APIs
│   ├── device/            # Device comm & device CRUD
│   ├── places/            # Saved places, saved routes, trips
│   ├── navigation/        # Navigation session, route calculation
│   └── offline_regions.rs # Offline map region management
│
├── domain/                # Domain Layer (pure business logic)
│   ├── entities.rs        # NavigationSession, Device, TrafficEvent
│   ├── value_objects.rs   # Position, GeocodingSearchResult, DeviceCapabilities, BatteryInfo
│   ├── events.rs          # NavigationEvent enum
│   └── ports.rs           # Port interfaces (RouteService, GeocodingService, NavigationRepository, …)
│
├── application/           # Application Layer
│   ├── commands.rs        # Navigation command structs (StartNavigation, UpdatePosition, …)
│   ├── queries.rs         # Query structs (GetActiveSession, GeocodeQuery, …)
│   └── handlers.rs        # Async handler structs with pub async fn handle()
│
├── infrastructure/        # Infrastructure Layer (Adapters)
│   ├── persistence/
│   │   ├── database.rs        # SQLite repositories (places, routes, trips, devices, regions)
│   │   ├── base_repository.rs # Generic CRUD base repository
│   │   ├── sqlite_navigation_repo.rs # SqliteNavigationRepository (production)
│   │   └── in_memory_repo.rs  # InMemoryNavigationRepository (test-only, #[cfg(test)])
│   └── device/
│       ├── no_op_device_comm.rs   # NoOpDeviceComm (default, swappable)
│       └── protobuf_adapter.rs    # ProtobufDeviceCommunicator (future BLE impl)
│
└── migrations/            # Database migrations
    └── m{timestamp}_{description}.rs
```

## Key Design Patterns

### 1. Thin FFI Wrapper Pattern

`nav_e_ffi` provides a minimal, stable API surface. All functions are simple pass-throughs:

```rust
// nav_e_ffi/src/lib.rs
#[frb]
pub fn calculate_route(waypoints: Vec<(f64, f64)>) -> Result<String> {
    nav_core::api::calculate_route(waypoints)
}
```

Initialization constructs services in `nav_e_ffi` and injects them into `nav_core`:

```rust
pub fn initialize_database(db_path: String) -> Result<()> {
    let route_service = Arc::new(nav_route::OsrmRouteService::new(
        "https://router.project-osrm.org".to_string(),
    ));
    let geocoding_service = Arc::new(nav_route::NominatimGeocodingService::new(
        "https://nominatim.openstreetmap.org".to_string(),
    ));
    nav_core::api::initialize_database(db_path, route_service, geocoding_service)
}
```

**Benefits:**
- FRB only scans `nav_e_ffi` — no internal type leakage
- Services are swappable without changing `nav_core`
- Clean separation between FFI boundary and business logic

### 2. Application Layer — Handlers

Handlers are plain async structs. Commands and queries are typed parameter bundles:

```rust
// No generic trait dispatch — plain async methods
impl StartNavigationHandler {
    pub async fn handle(&self, command: StartNavigationCommand) -> Result<NavigationSession> {
        let route = self.route_service.calculate_route(command.waypoints).await?;
        let session = NavigationSession::new(route.clone(), command.current_position);
        self.navigation_repo.save_session(&session).await?;
        let _ = self.event_bus.send(NavigationEvent::Started { session_id: session.id, route_id: route.id.0 });
        Ok(session)
    }
}
```

The application layer contains only navigation-related commands and queries. Saved places, routes, trips, and devices use repositories directly from the API layer (consistent direct-repo pattern throughout).

### 3. Domain Event Bus

`AppContext` holds a `broadcast::Sender<NavigationEvent>`. Handlers publish events; callers can subscribe:

```rust
// In nav_core
pub fn subscribe_navigation_events() -> broadcast::Receiver<NavigationEvent> {
    get_context().event_bus.subscribe()
}

// NavigationEvent variants
NavigationEvent::Started { session_id, route_id }
NavigationEvent::PositionUpdated { session_id, position }
NavigationEvent::WaypointReached { session_id, index }
NavigationEvent::Completed { session_id, distance_m }
NavigationEvent::Cancelled { session_id }
```

### 4. Generic Repository Pattern

```rust
pub trait Repository<T, ID>: Send + Sync {
    fn get_all(&self) -> Result<Vec<T>>;
    fn get_by_id(&self, id: ID) -> Result<Option<T>>;
    fn insert(&self, entity: T) -> Result<ID>;
    fn update(&self, id: ID, entity: T) -> Result<()>;
    fn delete(&self, id: ID) -> Result<()>;
}
```

`BaseRepository<T>` implements this with SQLite, eliminating CRUD boilerplate.

### 5. JSON Serialization Helpers

Consistent error handling and serialization across all APIs:

```rust
// Sync operations
pub fn query_json<F, T>(operation: F) -> Result<String>
pub fn command<F>(operation: F) -> Result<i64>

// Async operations (uses shared thread_local! tokio runtime)
pub fn query_json_async<T, F, Fut>(operation: F) -> Result<String>
pub fn command_async<F, Fut>(operation: F) -> Result<()>
```

## Quick Start

### 1. Generate Dart Bindings

```bash
make codegen
```

Runs `flutter_rust_bridge_codegen` pointing to `nav_e_ffi` and generates bindings in `lib/bridge/`.

### 2. Build Rust Library

**For desktop/testing:**
```bash
cargo build -p nav_e_ffi --release
```

**For Android:**
```bash
make build-android      # arm64 only
make build-android-all  # arm64, armv7, x86_64
```

### 3. Usage in Dart

```dart
import 'package:nav_e/bridge/lib.dart' as rust;

// Initialize (once, on app start)
await rust.initializeDatabase(dbPath: '/path/to/nav.db');

// Calculate route
final routeJson = await rust.calculateRoute(
  waypoints: [(37.7749, -122.4194), (37.8044, -122.2711)],
);

// Start navigation
final sessionJson = await rust.startNavigationSession(
  waypoints: [(37.7749, -122.4194), (37.8044, -122.2711)],
  currentPosition: (37.7749, -122.4194),
);
```

## API Conventions

### JSON vs Typed Returns

Most APIs return JSON strings for flexibility at the FFI boundary:
- `get_all_*` → JSON array
- `get_*_by_id` → JSON object (or null string)
- `save_*` → `i64` row ID
- `calculate_route`, `geocode_search` → JSON object/array

### Synchronous vs Asynchronous

- **Sync** (`#[frb(sync)]`): Database CRUD (saved places, routes, trips, devices)
- **Async**: Network operations (route calculation, geocoding, navigation session management)

All async FFI calls use a `thread_local!` tokio runtime via `block_on` — no per-call runtime creation.

### External Services (via `nav_route`)

- **Routing**: OSRM (`https://router.project-osrm.org`) — `OsrmRouteService`
- **Geocoding**: Nominatim (`https://nominatim.openstreetmap.org`) — `NominatimGeocodingService`

Both are feature-flagged (`osrm`, `nominatim`) in `nav_route/Cargo.toml`.

## Adding New Features

### Example: Adding Parking Zones

#### Step 1: Define domain entity (`nav_core/src/domain/entities.rs`)

```rust
pub struct ParkingZone {
    pub id: i64,
    pub location: Position,
    pub capacity: u32,
}
```

#### Step 2: Create repository (`nav_core/src/infrastructure/persistence/database.rs`)

Add a `ParkingZonesRepository` using `BaseRepository<ParkingZoneEntity>`.

#### Step 3: Add to AppContext (`nav_core/src/api/context.rs`)

Wire the repository into `AppContext` and populate in `initialize_database`.

#### Step 4: Create API module (`nav_core/src/api/parking_zones.rs`)

```rust
pub fn get_all_parking_zones() -> Result<String> {
    query_json(|| get_context().parking_zones_repo.get_all())
}
```

#### Step 5: Expose in nav_e_ffi (`nav_e_ffi/src/lib.rs`)

```rust
#[frb(sync)]
pub fn get_all_parking_zones() -> Result<String> {
    nav_core::api::get_all_parking_zones()
}
```

#### Step 6: Regenerate bindings

```bash
make codegen
```

## Testing

```bash
# Run all nav_core tests (77 tests covering domain, infra, migration, handler layers)
cargo test -p nav_core

# Check FFI wrapper compiles
cargo check -p nav_e_ffi

# Run a specific test
cargo test -p nav_core start_navigation_creates_active_session
```

### Test Structure

Tests live alongside source code in `#[cfg(test)] mod tests` blocks:
- `domain/entities.rs` — entity lifecycle, state transitions
- `domain/value_objects.rs` — validation, distance calculation
- `application/handlers.rs` — handler logic via `InMemoryNavigationRepository`
- `infrastructure/persistence/` — SQLite round-trips via in-memory SQLite
- `migrations/` — migration idempotency, rollback
