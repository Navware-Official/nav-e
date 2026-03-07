# Architecture Documentation

## Overview

The nav-e navigation engine has been restructured using **Domain-Driven Design (DDD)**, **Hexagonal Architecture** (Ports & Adapters), and **CQRS** (Command Query Responsibility Segregation) patterns.

## Architecture Layers

### 1. Domain Layer (`src/domain/`)

Pure business logic with zero external dependencies. Contains:

#### **Entities** (`entities.rs`)
Core business objects with identity:
- `NavigationSession` - Active navigation with route and position
- `Route` - Route with waypoints and polyline
- `Device` - Connected navigation device (Wear OS watch, BLE device)
- `TrafficEvent` - Traffic alert affecting navigation

#### **Value Objects** (`value_objects.rs`)
Immutable objects defined by attributes:
- `Position` - Geographic coordinates with validation
- `Waypoint` - Point in a route
- `DeviceCapabilities` - Device features (screen, battery, sensors)
- `BatteryInfo` - Power status with critical/low thresholds
- `Instruction` - Turn-by-turn directions

#### **Ports** (`ports.rs`)
Interfaces defining contracts (Dependency Inversion):
- **Primary Ports** (driven by app):
  - `DeviceCommunicationPort` - Send messages to devices
- **Secondary Ports** (driving app):
  - `RouteService` - Calculate routes
  - `GeocodingService` - Address ↔ coordinates
  - `NavigationRepository` - Persist navigation state
  - `TrafficService` - Real-time traffic data
  - `DeviceMessageReceiver` - Handle incoming device messages

#### **Events** (`events.rs`)
Domain events published to an in-process `broadcast` channel. A single enum covers all navigation lifecycle events:

```rust
pub enum NavigationEvent {
    Started { session_id: Uuid, route_id: Uuid },
    PositionUpdated { session_id: Uuid, position: Position },
    WaypointReached { session_id: Uuid, index: usize },
    Completed { session_id: Uuid, distance_m: f64 },
    Cancelled { session_id },
}
```

Callers subscribe via `nav_core::api::subscribe_navigation_events() -> broadcast::Receiver<NavigationEvent>`.

### 2. Application Layer (`src/application/`)

Orchestrates business logic using CQRS pattern.

#### **Commands** (`commands.rs`)
Typed parameter bundles for write operations:
- `StartNavigationCommand` — waypoints, current position, optional device ID
- `UpdatePositionCommand` — session ID, new position
- `PauseNavigationCommand` / `ResumeNavigationCommand` — session ID
- `StopNavigationCommand` — session ID, completed flag

#### **Queries** (`queries.rs`)
Typed parameter bundles for read operations:
- `GetActiveSessionQuery` — returns the active `NavigationSession`
- `GeocodeQuery` — address string + limit
- `ReverseGeocodeQuery` — `Position`

Saved places, routes, trips, and devices use repository methods directly from the API layer — no command/query wrappers for simple CRUD.

#### **Handlers** (`handlers.rs`)
Plain async structs with a `pub async fn handle` method. No generic trait dispatch:
- `StartNavigationHandler` — calculates route, creates session, notifies device, publishes `NavigationEvent::Started`
- `UpdatePositionHandler` — loads session, updates position, detects waypoint proximity, publishes events
- `PauseNavigationHandler` / `ResumeNavigationHandler` — load, mutate status, save
- `StopNavigationHandler` — completes or cancels session, publishes event
- `GetActiveSessionHandler` — delegates to `NavigationRepository::load_active_session`
- `GeocodeHandler` / `ReverseGeocodeHandler` — delegate to `GeocodingService`

### 3. Infrastructure Layer (`src/infrastructure/` + `nav_route` crate)

Adapters implementing domain ports, split across two crates:

**`nav_core/src/infrastructure/`** — persistence and device adapters:
- **`persistence/database.rs`** — `Database`, SQLite repositories for places, routes, trips, devices, offline regions
- **`persistence/base_repository.rs`** — generic `BaseRepository<T>` with CRUD via `Repository<T, ID>` trait
- **`persistence/sqlite_navigation_repo.rs`** — `SqliteNavigationRepository` (production navigation state)
- **`persistence/in_memory_repo.rs`** — `InMemoryNavigationRepository` (**test-only**, `#[cfg(test)]`)
- **`device/no_op_device_comm.rs`** — `NoOpDeviceComm` (default, swappable)
- **`device/protobuf_adapter.rs`** — `ProtobufDeviceCommunicator` (future BLE impl)

**`nav_route/`** — routing and geocoding adapters (separate crate, feature-flagged):
```rust
// nav_route implements nav_core port traits
impl RouteService for OsrmRouteService {                // feature: osrm
    async fn calculate_route(&self, waypoints: Vec<Position>) -> Result<NavIrRoute>
    async fn recalculate_from_position(&self, route: &NavIrRoute, current_position: Position) -> Result<NavIrRoute>
}

impl GeocodingService for NominatimGeocodingService {   // feature: nominatim
    async fn geocode(&self, address: &str, limit: Option<u32>) -> Result<Vec<GeocodingSearchResult>>
    async fn reverse_geocode(&self, position: Position) -> Result<String>
}
```

`nav_e_ffi` constructs and injects these services into `nav_core` at startup. `nav_core` itself has no dependency on `nav_route`.

### 3.5 API Layer (`src/api/`)

Feature-based API surface used by nav_e_ffi and Flutter. Organized by domain:

- **`context.rs`** – AppContext, `get_context()`, `initialize_database()` (bootstrap)
- **`dto.rs`**, **`helpers.rs`** – shared DTOs and query/command helpers
- **`device/`** – device_comm (prepare_route_message, BLE/protobuf), devices (CRUD)
- **`places/`** – saved_places, saved_routes, trips
- **`navigation/`** – navigation (session start/update/pause/stop), routes (calculate_route)
- **`geocoding.rs`**, **`offline_regions.rs`** – geocoding and offline map regions

All public API functions are re-exported from `api` so `nav_core::api::*` (and thus nav_e_ffi) stays unchanged.

### 4. Protocol Buffers (`proto/`)

See `proto/README.md` for message specification.

## Flutter Integration

### Device Communication Service

**`lib/core/device_comm/device_communication_service.dart`**

Handles Protocol Buffers serialization and device transport:

```dart
class DeviceCommunicationService {
  // Send messages
  Future<void> sendRouteSummary(String deviceId, RouteSummary summary)
  Future<void> sendRouteBlob(String deviceId, RouteBlob blob)
  Future<void> sendPositionUpdate(String deviceId, PositionUpdate update)
  Future<void> sendTrafficAlert(String deviceId, TrafficAlert alert)
  
  // Receive messages
  Stream<DeviceMessage> get messageStream
  void handleIncomingData(String deviceId, Uint8List data)
  
  // Device management
  void registerDevice(String deviceId, String name, DeviceType type)
  List<ConnectedDevice> get connectedDevices
}
```

### BLoC Integration

**`lib/core/bloc/device_comm_bloc.dart`**

State management for device communication:

```dart
// Events
DeviceConnected(deviceId, name, type)
DeviceDisconnected(deviceId)
SendRouteToDevice(deviceId, routeBlob)
SendPositionToDevice(deviceId, position)
SendTrafficAlertToDevice(deviceId, alert)
MessageReceived(message)
DeviceBatteryUpdated(deviceId, batteryStatus)

// States
DeviceCommInitial
DeviceCommLoading
DeviceCommReady(devices, batteryStatuses, recentMessages)
DeviceCommError(message)
```

## Benefits of This Architecture

### 1. **Testability**
- Domain logic isolated from infrastructure
- Mock ports for unit testing
- Test handlers without external dependencies

### 2. **Flexibility**
- Swap implementations (OSRM → Google Maps, BLE → WebSocket)
- Add new adapters without touching domain
- Multiple storage backends (in-memory, SQLite, etc.)

### 3. **Maintainability**
- Clear separation of concerns
- Single Responsibility Principle
- Business logic in one place (domain layer)

### 4. **Scalability**
- CQRS enables read/write optimization
- Event sourcing for audit trails
- Async/await throughout

### 5. **Domain Focus**
- Business rules explicit in code
- Ubiquitous language (navigation, waypoint, session)
- Complex logic stays in domain, not scattered

## Usage Example

### Rust Side

Services are injected at startup by `nav_e_ffi`. Application code then calls API functions directly:

```rust
// nav_e_ffi initialises the engine once
nav_core::api::initialize_database(db_path, route_service, geocoding_service)?;

// nav_core API layer creates and runs handlers internally
let session_json = nav_core::api::start_navigation_session(waypoints, current_pos)?;

// Subscribe to live navigation events
let mut rx = nav_core::api::subscribe_navigation_events();
tokio::spawn(async move {
    while let Ok(event) = rx.recv().await {
        match event {
            NavigationEvent::PositionUpdated { session_id, position } => { /* … */ }
            NavigationEvent::WaypointReached { session_id, index } => { /* … */ }
            _ => {}
        }
    }
});
```

### Flutter Side

```dart
// Setup
final deviceService = DeviceCommunicationService();
final deviceBloc = DeviceCommBloc(deviceService);

// Connect device
deviceBloc.add(DeviceConnected('watch-123', 'Galaxy Watch', DeviceType.wearOsWatch));

// Send route
final routeBlob = RouteBlob()
  ..routeData = encodedRoute
  ..totalWaypoints = 5;
deviceBloc.add(SendRouteToDevice('watch-123', routeBlob));

// Listen for messages
deviceBloc.stream.listen((state) {
  if (state is DeviceCommReady) {
    print('Devices: ${state.devices.length}');
    print('Battery: ${state.batteryStatuses}');
  }
});
```

## References

- [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)
- [Domain-Driven Design](https://martinfowler.com/bliki/DomainDrivenDesign.html)
- [CQRS Pattern](https://martinfowler.com/bliki/CQRS.html)
- [Protocol Buffers](https://protobuf.dev/)
