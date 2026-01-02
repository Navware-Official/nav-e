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
Domain events for event sourcing:
- `NavigationStartedEvent`
- `PositionUpdatedEvent`
- `WaypointReachedEvent`
- `NavigationCompletedEvent`
- `DeviceConnectedEvent`
- `TrafficAlertDetectedEvent`

### 2. Application Layer (`src/application/`)

Orchestrates business logic using CQRS pattern.

#### **Commands** (`commands.rs`)
Write operations that change state:
- `StartNavigationCommand` - Begin new navigation session
- `UpdatePositionCommand` - Update current GPS position
- `PauseNavigationCommand` / `ResumeNavigationCommand`
- `StopNavigationCommand` - Complete or cancel
- `RegisterDeviceCommand` - Connect new device
- `SendRouteToDeviceCommand` - Push route to device
- `ReportTrafficCommand` - Log traffic event

#### **Queries** (`queries.rs`)
Read operations that don't modify state:
- `GetActiveSessionQuery` - Get current navigation
- `GetSessionQuery` - Get session by ID
- `GetConnectedDevicesQuery` - List devices
- `GetTrafficAlertsQuery` - Get traffic for route
- `CalculateRouteQuery` - Plan route without starting
- `GeocodeQuery` / `ReverseGeocodeQuery` - Address lookup

#### **Handlers** (`handlers.rs`)
Execute commands and queries:
- `StartNavigationHandler` - Calculates route, creates session, sends to device
- `UpdatePositionHandler` - Updates position, detects waypoint arrival
- `CalculateRouteHandler` - Uses RouteService port
- `GeocodeHandler` / `ReverseGeocodeHandler` - Uses GeocodingService port

### 3. Infrastructure Layer (`src/infrastructure/`)

Adapters implementing domain ports (Hexagonal Architecture).

#### **Adapters**

**`osrm_adapter.rs`** - OSRM routing implementation
```rust
impl RouteService for OsrmRouteService {
    async fn calculate_route(&self, waypoints: Vec<Position>) -> Result<Route>
    async fn recalculate_from_position(&self, route: &Route, current_position: Position) -> Result<Route>
}
```

**`geocoding_adapter.rs`** - Photon geocoding
```rust
impl GeocodingService for PhotonGeocodingService {
    async fn geocode(&self, address: &str) -> Result<Vec<Position>>
    async fn reverse_geocode(&self, position: Position) -> Result<String>
}
```

**`protobuf_adapter.rs`** - Device communication via Protocol Buffers
```rust
impl DeviceCommunicationPort for ProtobufDeviceCommunicator {
    async fn send_route_summary(&self, device_id: &str, session: &NavigationSession) -> Result<()>
    async fn send_route_blob(&self, device_id: &str, route: &Route) -> Result<()>
    async fn send_position_update(&self, device_id: &str, position: Position) -> Result<()>
    async fn send_traffic_alert(&self, device_id: &str, event: &TrafficEvent) -> Result<()>
}
```

**`in_memory_repo.rs`** - In-memory navigation state (for testing/development)
```rust
impl NavigationRepository for InMemoryNavigationRepository {
    async fn save_session(&self, session: &NavigationSession) -> Result<()>
    async fn load_active_session(&self) -> Result<Option<NavigationSession>>
}
```

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

```rust
use nav_engine::application::{commands::*, handlers::*};
use nav_engine::infrastructure::*;

// Setup dependencies (Hexagonal Architecture)
let route_service = Arc::new(OsrmRouteService::new("https://router.project-osrm.org".into()));
let navigation_repo = Arc::new(InMemoryNavigationRepository::new());
let geocoding_service = Arc::new(PhotonGeocodingService::new("https://photon.komoot.io".into()));
let device_comm = Arc::new(ProtobufDeviceCommunicator::new(transport));

// Create handlers
let start_handler = StartNavigationHandler::new(
    route_service.clone(),
    navigation_repo.clone(),
    device_comm.clone()
);

// Execute command
let command = StartNavigationCommand {
    waypoints: vec![start_pos, end_pos],
    current_position: start_pos,
    device_id: Some("watch-123".into()),
};

let session = start_handler.handle(command).await?;
println!("Navigation started: {}", session.id);
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
