# Nav Engine - Rust Core

A production-ready Rust navigation engine using **DDD/Hexagonal/CQRS** architecture, exposed to Flutter via `flutter_rust_bridge` through a dedicated thin FFI wrapper crate.

## Architecture Overview

The project uses a **two-crate architecture** to cleanly separate business logic from FFI concerns:

```
native/
├── nav_engine/            # Core navigation engine (internal)
│   └── src/
│       ├── api/           # Internal API layer
│       ├── domain/        # Domain layer (entities, value objects, ports)
│       ├── application/   # Application layer (CQRS handlers)
│       ├── infrastructure/# Infrastructure adapters
│       └── migrations/    # Database migrations
│
└── nav_e_ffi/             # Thin FFI wrapper (public API)
    └── src/
        └── lib.rs         # 20 public functions forwarding to nav_engine

flutter/lib/bridge/        # Generated Dart bindings
    ├── frb_generated.dart
    ├── frb_generated.io.dart
    └── lib.dart           # Public API (automatically generated)
```

### Core Engine Structure (`nav_engine`)

```
native/nav_engine/src/
├── api/                    # Internal API Layer (Feature-based modules)
│   ├── mod.rs             # AppContext and module coordination
│   ├── dto.rs             # Data Transfer Objects & conversions
│   ├── helpers.rs         # JSON serialization helpers
│   ├── routes.rs          # Route calculation APIs
│   ├── navigation.rs      # Navigation session APIs
│   ├── geocoding.rs       # Geocoding APIs (Nominatim)
│   ├── saved_places.rs    # Saved places CRUD APIs
│   └── devices.rs         # Device management APIs
│
├── domain/                # Domain Layer (Core business logic)
│   ├── entities.rs        # Domain entities (NavigationSession, Route, Device)
│   ├── value_objects.rs   # Value objects (Position, Waypoint, etc.)
│   ├── events.rs          # Domain events
│   └── ports.rs           # Port interfaces (traits)
│
├── application/           # Application Layer (CQRS)
│   ├── commands.rs        # Write operations (Commands)
│   ├── queries.rs         # Read operations (Queries)
│   ├── handlers.rs        # Command & Query handlers
│   ├── traits.rs          # Generic handler traits
│   └── service_helpers.rs # Service utilities
│
├── infrastructure/        # Infrastructure Layer (Adapters)
│   ├── database.rs        # SQLite repositories
│   ├── base_repository.rs # Generic repository implementation
│   ├── osrm_adapter.rs    # OSRM route service
│   ├── geocoding_adapter.rs # Nominatim geocoding service
│   └── protobuf_adapter.rs# Device communication
│
└── migrations/            # Database migrations
    └── m*.rs              # Migration files
```

## Key Design Patterns

### 1. Thin FFI Wrapper Pattern

The `nav_e_ffi` crate provides a minimal, stable API surface:

**Benefits:**
- ✅ FRB only scans the wrapper crate (no internal type leakage)
- ✅ Clean separation between FFI and business logic
- ✅ No cleanup scripts needed
- ✅ Predictable code generation
- ✅ Easy to expose engine to other platforms (Wear OS, embedded devices)

**Implementation:**
```rust
// nav_e_ffi/src/lib.rs
#[frb]
pub fn calculate_route(waypoints: Vec<(f64, f64)>) -> Result<String> {
    nav_engine::api::calculate_route(waypoints)
}
```

All functions are simple pass-throughs to the core engine.

### 2. Feature-Based API Organization

APIs are organized by feature domain rather than a monolithic file:

- **`api/routes.rs`** - Route calculation (OSRM integration)
- **`api/navigation.rs`** - Navigation session management  
- **`api/geocoding.rs`** - Forward/reverse geocoding (Nominatim)
- **`api/saved_places.rs`** - Saved places CRUD (SQLite)
- **`api/devices.rs`** - Device management (SQLite)

Each module is self-contained and focused on a single feature.

### 2. Generic Repository Pattern

Base repository with common CRUD operations:

```rust
pub trait Repository<T, ID>: Send + Sync {
    fn get_all(&self) -> Result<Vec<T>>;
    fn get_by_id(&self, id: ID) -> Result<Option<T>>;
    fn insert(&self, entity: T) -> Result<ID>;
    fn update(&self, id: ID, entity: T) -> Result<()>;
    fn delete(&self, id: ID) -> Result<()>;
}
```

Specialized repositories extend this pattern.

### 3. CQRS with Generic Handlers

Commands (writes) and queries (reads) separated with generic traits:

```rust
#[async_trait]
pub trait CommandHandler<TCommand, TResult> {
    async fn handle(&self, command: TCommand) -> Result<TResult>;
}

#[async_trait]
pub trait QueryHandler<TQuery, TResult> {
    async fn handle(&self, query: TQuery) -> Result<TResult>;
}
```

All handlers implement these traits for consistency.

### 4. DTO Conversion Functions

Clean separation between domain entities and FFI-safe DTOs:

```rust
// Internal conversion functions (not exposed to FFI)
pub(crate) fn route_to_dto(route: Route) -> RouteDto { ... }
pub(crate) fn navigation_session_to_dto(session: NavigationSession) -> NavigationSessionDto { ... }
```

### 5. JSON Serialization Helpers

Consistent error handling and serialization across all APIs:

```rust
// Sync operations
pub fn query_json<F, T>(operation: F) -> Result<String>
pub fn command<F>(operation: F) -> Result<i64>

// Async operations
pub fn query_json_async<T, F, Fut>(operation: F) -> Result<String>
pub fn command_async<F, Fut>(operation: F) -> Result<()>
```

## Quick Start

### 1. Generate Dart Bindings

```bash
make codegen
```

This runs `flutter_rust_bridge_codegen` pointing to the `nav_e_ffi` crate and generates bindings in `lib/bridge/`.

### 2. Build Rust Library

**For desktop/testing:**
```bash
cd native/nav_e_ffi
cargo build --release
```

**For Android:**
```bash
make build-android      # arm64 only
make build-android-all  # arm64, armv7, x86_64
```

### 3. Generated Dart Structure

```
lib/bridge/
├── frb_generated.dart     # Core FRB infrastructure
├── frb_generated.io.dart  # Platform-specific (iOS/Android)
└── lib.dart               # Public API - all 20 functions
```

**Clean output - no internal directories!** 

The old structure had unwanted `application/`, `domain/`, `infrastructure/` directories. The new FFI wrapper architecture eliminates this.

### 4. Usage in Dart

```dart
import 'package:nav_e/bridge/lib.dart' as rust;

// Calculate route
final routeJson = await rust.calculateRoute(
  waypoints: [(37.7749, -122.4194), (37.8044, -122.2711)],
);

// Start navigation
final sessionJson = await rust.startNavigationSession(
  waypoints: [(37.7749, -122.4194), (37.8044, -122.2711)],
  currentPosition: (37.7749, -122.4194),
## API Conventions

### JSON vs Typed Returns

Most APIs return JSON strings for flexibility:

```rust
// In nav_engine::api
pub fn calculate_route(waypoints: Vec<(f64, f64)>) -> Result<String> {
    query_json_async(|| async {
        // ... implementation
        Ok(route_to_dto(route))
    })
}

// In nav_e_ffi (wrapper)
#[frb]
pub fn calculate_route(waypoints: Vec<(f64, f64)>) -> Result<String> {
    nav_engine::api::calculate_route(waypoints)
}
```

This allows:
- Easy serialization/deserialization on Dart side
- Flexibility in response handling
- Consistent error handling
- Clean FFI boundary without complex types

### Synchronous vs Asynchronous

- **Sync** (`#[frb(sync)]`): Database CRUD operations (saved_places, devices)
- **Async**: Network operations (routes, geocoding, navigation)

### External Services

- **Routing**: OSRM (`https://router.project-osrm.org`)
- **Geocoding**: Nominatim (`https://nominatim.openstreetmap.org`)
  - Forward search: `/search?q={query}&format=json&limit={limit}&addressdetails=1`
  - Reverse geocoding: `/reverse?lat={lat}&lon={lon}&format=json`
  - User-Agent: "NavE Navigation App/1.0" (required by Nominatim)
### JSON vs Typed Returns

Most APIs return JSON strings for flexibility:

```rust
#[frb]
pub fn calculate_route(waypoints: Vec<(f64, f64)>) -> Result<String> {
    query_json_async(|| async {
        // ... implementation
## Adding New Features

### Example: Adding Parking Zones

#### Step 1: Define in `nav_engine`

1. **Define domain entity** (`nav_engine/src/domain/entities.rs`):
```rust
pub struct ParkingZone {
    pub id: Uuid,
    pub location: Position,
    pub capacity: u32,
    // ...
}
```

2. **Create repository** (`nav_engine/src/infrastructure/database.rs`):
```rust
pub struct ParkingZoneRepository {
    base: BaseRepository<ParkingZoneEntity>,
}
```

3. **Create API module** (`nav_engine/src/api/parking_zones.rs`):
```rust
pub fn get_all_parking_zones() -> Result<String> {
    query_json(|| get_context().parking_zones_repo.get_all())
}

pub fn save_parking_zone(name: String, lat: f64, lon: f64, capacity: u32) -> Result<i64> {
    // implementation
}
```

4. **Register in mod.rs** (`nav_engine/src/api/mod.rs`):
```rust
pub(crate) mod parking_zones;
pub use parking_zones::*;
## Testing

### Rust Tests

```bash
# Test core engine
cd native/nav_engine
cargo test

# Test FFI wrapper
cd native/nav_e_ffi
cargo check  # FFI layer is thin, mainly checking compilation

# Run specific test
cargo test test_route_to_dto
```

### Flutter Tests

```bash
# Run Dart tests
flutter test

# Run integration tests
flutter test integration_test/
```

## Configuration Files

### `flutter_rust_bridge.yaml`

```yaml
rust_input: "crate"
rust_root: "native/nav_e_ffi/"  # Points to wrapper, not engine!
dart_output: "lib/bridge"
dart_entrypoint_class_name: "RustBridge"
web: false
```

**Important:** `rust_root` points to `nav_e_ffi`, ensuring FRB only sees the public API.

### `Makefile` Targets

```bash
make codegen          # Generate FRB bindings
make build-native     # Build nav_e_ffi for desktop
make build-android    # Build for Android (arm64)
make build-android-all# Build for Android (all ABIs)
make clean-native     # Clean both crates
make fmt              # Format both crates
make test             # Run Flutter tests
```

## Debugging

### Adding Debug Logs

**Rust (use `eprintln!` for stderr):**
```rust
pub fn geocode_search(query: String, limit: Option<u32>) -> Result<String> {
    eprintln!("[GEOCODING] Query: {}", query);
    // ... implementation
    eprintln!("[GEOCODING] Returning {} results", results.len());
}
```

**Dart:**
```dart
print('[MY FEATURE] Debug info: $data');
```

### View Logs

```bash
# Flutter logs
flutter run -v

# Android logcat (filtered)
adb logcat | grep -E "GEOCODING|flutter|RUST"

# See all stderr from Rust
adb logcat | grep "System.err"
```

## Migration from Old Architecture

The project recently migrated from directly exposing `nav_engine` to using the `nav_e_ffi` wrapper:

**Old (problematic):**
```yaml
# flutter_rust_bridge.yaml
rust_input: "crate::api"
rust_root: "native/nav_engine/"  # ❌ FRB scanned internal types
```

**New (clean):**
```yaml
rust_input: "crate"
rust_root: "native/nav_e_ffi/"  # ✅ FRB only sees wrapper
```

**Dart import changes:**
```dart
// Old (multiple files)
import 'package:nav_e/bridge/api/routes.dart' as routes_api;
import 'package:nav_e/bridge/api/navigation.dart' as nav_api;
routes_api.calculateRoute(...)

// New (single namespace)
import 'package:nav_e/bridge/lib.dart' as rust;
rust.calculateRoute(...)
```rb(sync)]
pub fn get_all_parking_zones() -> Result<String> {
    nav_engine::api::get_all_parking_zones()
}

/// Save a parking zone and return the assigned ID
#[frb(sync)]
pub fn save_parking_zone(
    name: String,
    lat: f64,
    lon: f64,
    capacity: u32,
) -> Result<i64> {
    nav_engine::api::save_parking_zone(name, lat, lon, capacity)
}
```

#### Step 3: Regenerate bindings

```bash
make codegen
```

That's it! The new functions appear in `lib/bridge/lib.dart` automatically.
3. **Create API module** (`api/parking_zones.rs`):
```rust
#[frb(sync)]
pub fn get_all_parking_zones() -> Result<String> {
    query_json(|| get_context().parking_zones_repo.get_all())
}
```

4. **Register in mod.rs**:
```rust
mod parking_zones;
pub use parking_zones::*;
```

That's it! The helper functions and traits handle the rest.

## Testing

```bash
# Run all tests
cargo test --manifest-path native/nav_engine/Cargo.toml

# Run specific test
cargo test --manifest-path native/nav_engine/Cargo.toml test_route_to_dto
```
