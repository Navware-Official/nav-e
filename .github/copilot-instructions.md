# Copilot Instructions for nav-e

This document guides AI agents on the architecture, patterns, and workflows for the nav-e navigation engine codebase.

## Project Overview

**nav-e** is a Flutter-based navigation application integrating:
- **Flutter UI** with BLoC state management and GoRouter navigation
- **Rust core** (via FFI via `flutter_rust_bridge`) for performance-critical operations
- **Domain-Driven Design** architecture with Hexagonal Architecture and CQRS patterns
- **Navigation services**: OSRM routing, Nominatim geocoding, Bluetooth device communication
- **Multi-platform**: Android (primary), iOS (planned)

**Key repo branch**: `feature/navigation-routing` contains the DDD/Hexagonal architecture implementation.

---

## Architecture Patterns (Critical)

### Domain-Driven Design + Hexagonal Architecture + CQRS (Rust Core)

The Rust native layer (`native/nav_engine/src/`) uses three complementary patterns:

**Layer Structure:**
```
domain/          → Pure business logic (Entities, Value Objects, Ports, Events, no dependencies)
application/     → CQRS (Commands, Queries, Handlers orchestrate domain)
infrastructure/  → Adapters implement domain ports (OSRM, Nominatim, Protobuf, SQLite)
```

**When implementing Rust features:**
1. Define domain **entities** (e.g., `NavigationSession`, `Route`) with business invariants
2. Create **ports** (traits) for external dependencies (e.g., `RouteService` for OSRM)
3. Add **commands** (write) or **queries** (read) in application layer
4. Implement **handlers** that use domain logic and inject ports
5. Create **adapters** in infrastructure that implement ports (never let adapters call domain directly)

**Example**: Routing flow uses `CalculateRouteHandler` → calls `RouteService` (port) → `OsrmRouteService` (adapter) implementation.

Reference: `docs/adr/0001-adopt-ddd-hexagonal-cqrs.md`, `docs/architecture/overview.md`

### Flutter Layer: BLoC + Repository Pattern

**State Management:**
- Use `flutter_bloc: ^9.1.1` for events → state transformation
- Events are input (e.g., `StartLocationTracking`)
- State holds current data (immutable with `copyWith()`)
- Handlers transform events using repositories

**Example (LocationBloc):**
```dart
abstract class LocationEvent {}
class StartLocationTracking extends LocationEvent {}

class LocationState {
  final LatLng? position;
  final double? heading;
  final bool tracking;
  LocationState copyWith({...}) => LocationState(...);
}

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc() : super(LocationState()) {
    on<StartLocationTracking>(_startTracking);
  }
  Future<void> _startTracking(event, emit) async { ... }
}
```

**Repositories:**
- Interface in `lib/core/domain/repositories/` (e.g., `IGeocodingRepository`)
- Implementation in feature's `data/` folder (e.g., `lib/features/search/data/GeocodingRepositoryFrbTypedImpl`)
- Implementations call Rust FFI via `flutter_rust_bridge`

**Dependency Injection:**
- Repositories provided via `MultiRepositoryProvider` in `main.dart`
- BLoCs retrieve via `RepositoryProvider.of<T>(context)` in event handlers

---

## Flutter-Rust Integration (flutter_rust_bridge)

### FFI Boundary

**Rust→Dart codegen:**
```bash
make codegen  # Runs flutter_rust_bridge_codegen, outputs to lib/bridge/
```

After changing Rust function signatures, regenerate before rebuilding.

**Key patterns:**
- Import generated bridge: `import 'package:nav_e/bridge/lib.dart' as rust_api;`
- Call async Rust functions: `await rust_api.functionName(args)`
- Protobuf serialization happens in Rust; Dart receives `Uint8List` or JSON strings

**Example device communication:**
```dart
// Dart side (Flutter)
final message = await rust_api.prepareRouteMessage(routeJson: jsonEncode(route));
// Rust receives JSON, returns Protobuf bytes for BLE transmission
```

### Build Process

**When changing Rust code:**
1. **Signature changes** → `make full-rebuild` (codegen + Android libs)
2. **Implementation only** → `make rust-only` (skip codegen, rebuild Android libs)
3. **Local testing** → `make build-native` (desktop testing)

**Android builds require `cargo-ndk`:**
```bash
cargo install cargo-ndk
make build-android  # arm64-v8a only (fast)
make build-android-all  # arm64-v8a, armeabi-v7a, x86_64 (slow, for release)
```

---

## File Organization

### Dart/Flutter (`lib/`)
```
lib/
  main.dart              → App entry, repository & BLoC provider setup
  app/
    app_router.dart      → GoRouter configuration for navigation
    app_nav.dart         → Navigation models
  core/
    bloc/                → Shared BLoCs (LocationBloc, BluetoothBloc, ThemeCubit)
    domain/
      repositories/      → Repository interfaces (IGeocodingRepository, etc.)
      models/            → Shared domain models
    data/
      remote/            → HTTP clients (MapSourceRepository)
    theme/               → Material Design theme, ThemeCubit
    constants/           → App-wide constants
  features/              → Feature modules (each with domain/presentation/data layers)
    map_layers/          → Map rendering (MapBloc)
    search/              → Geocoding search (uses GeocodingRepository)
    device_management/   → Device list management (DevicesBloc)
    device_comm/         → Send routes to devices (DeviceCommBloc, DeviceCommunicationService)
    saved_places/        → Saved locations
    nav/                 → Active navigation
    plan_route/          → Route planning UI
    home/                → Home screen
    settings/            → App settings
  widgets/               → Reusable UI components
  bridge/                → Generated flutter_rust_bridge code (DO NOT EDIT)
```

### Rust (`native/`)
```
native/
  nav_engine/            → Core navigation logic (DDD)
    src/
      domain/            → Entities, Value Objects, Ports, Events (no external deps)
      application/       → Commands, Queries, Handlers (uses domain + ports)
      infrastructure/    → Adapters (OSRM, Nominatim, Protobuf, SQLite)
    Cargo.toml
  nav_e_ffi/             → FFI wrapper for Flutter integration
    src/
      lib.rs             → Exposed Rust functions for Dart
  device_comm/           → BLE frame chunking & protocol (separate crate)
    src/
      frame.rs           → Frame structure, CRC, serialization
      chunker.rs         → Message → chunks
```

---

## Key Workflows

### Adding a New Feature (Cross-Stack)

1. **Dart BLoC/UI** (`lib/features/your_feature/`)
   - Create events, state, bloc in `presentation/bloc/`
   - Create screens in `presentation/screens/`
   - Create repository interface in `domain/repositories/`
   - Create repository impl in `data/` (call Rust if needed)

2. **Rust Implementation** (`native/nav_engine/src/`)
   - Add domain entities/value objects
   - Create port (interface) for external services
   - Add command/query in application layer
   - Implement handler using ports (dependency injection)
   - Create adapter if integrating external service (OSRM, Nominatim, etc.)

3. **FFI Binding** (`native/nav_e_ffi/src/lib.rs`)
   - Expose public function from nav_engine
   - Mark with `#[uniffi::export]` for flutter_rust_bridge
   - `make codegen` to generate Dart bindings

4. **Testing**
   - **Dart**: `flutter test test/features/your_feature/`
   - **Rust**: `cd native/nav_engine && cargo test`

### Routing a Message to Device

**Flow:** UI → BLoC → Service → FFI → Rust → BLE → Device

1. **UI triggers**: User taps "Send to Device" button
2. **BLoC event**: `SendRouteToDevice` emitted to `DeviceCommBloc`
3. **Service**: `DeviceCommunicationService.sendRoute()` calls `FFI.prepareRouteMessage()`
4. **Rust processing**: `prepareRouteMessage()` serializes to Protobuf in nav_engine
5. **BLE chunking**: `chunkMessageForBle()` splits using device_comm crate
6. **Transmission**: Frames sent via `flutter_blue_plus` characteristics
7. **Progress feedback**: BLoC emits `DeviceCommSending(progress)` states

Reference: `docs/guides/device-communication.md`

### Testing Rust Code

```bash
# Unit tests
cd native/nav_engine && cargo test

# Clippy linting (fail on warnings for nav_engine, warnings allowed for nav_e_ffi)
make lint-rust

# Format
make fmt-rust
```

### Testing Flutter Code

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/bloc/location_bloc_test.dart

# Coverage (if configured)
flutter test --coverage
```

---

## Critical Patterns & Conventions

### Immutable Data (Dart)
- States: Use `copyWith()` for updates (see `LocationState`)
- Events: Keep simple, immutable
- Models: Use `@immutable` or data classes (freezed recommended)

### Async/Await (Rust & Dart)
- All operations are async; always `await` FFI calls
- Rust handlers are `async fn`; use `.await` for service calls
- Dart BLoC: Never block in event handlers; always use `emit.forEach()` for streams or `await` for futures

### Dependency Injection (Hexagonal Pattern)
- **Rust**: Ports are injected into handlers via struct fields
- **Dart**: Repositories injected via `RepositoryProvider.of<T>(context)`
- **Never** hardcode service instantiation in domain/application layers

### Error Handling
- **Rust**: Use `Result<T, E>` from domain; propagate via handlers
- **Dart**: Try-catch in repository, emit error states in BLoC
- Display errors in UI via state (e.g., `DeviceCommError(message)`)

### Protocol Buffers (Device Communication)
- Defined in `proto/navigation.proto`
- Generated Rust code via `protoc_plugin`
- Regenerate: `make codegen`
- Use for device communication only; not for app internal data

---

## Common Commands

```bash
# Development workflow
make full-rebuild           # After changing Rust signatures
make android-dev            # Full rebuild + flutter run
make rust-only              # Rebuild Android libs only

# Code quality
make fmt                    # Format Rust + Dart
make lint                   # Lint Rust + Dart
make cs-fix                 # Auto-fix style issues

# Testing
make test                   # Run all tests (Flutter + Rust)
flutter test                # Flutter tests only
cd native/nav_engine && cargo test   # Rust tests only

# Database migrations
make migrate-new            # Create migration file
make migrate-status         # Show applied/pending
```

---

## When You're Stuck

1. **Architecture confusion**: Read `docs/adr/0001-adopt-ddd-hexagonal-cqrs.md` and `docs/architecture/overview.md`
2. **Device communication**: Check `docs/guides/device-communication.md` and `docs/rust/device-comm.md`
3. **FFI integration**: See `docs/guides/flutter-rust-bridge.md`
4. **Example patterns**: Look at `lib/core/bloc/location_bloc.dart` (BLoC), `lib/features/search/data/` (Repository), and `native/nav_engine/src/application/` (CQRS)
5. **Build issues**: Ensure `cargo-ndk` is installed; run `make clean-native && make full-rebuild`

---

## Quick Reference: File Locations

| What | Where |
|------|-------|
| App entry & DI setup | `lib/main.dart` |
| Routing configuration | `lib/app/app_router.dart` |
| Repository interfaces | `lib/core/domain/repositories/` |
| Location tracking BLoC | `lib/core/bloc/location_bloc.dart` |
| Search/Geocoding | `lib/features/search/` |
| Device communication | `lib/features/device_comm/`, `lib/features/device_management/` |
| Rust domain logic | `native/nav_engine/src/domain/` |
| Rust handlers (CQRS) | `native/nav_engine/src/application/` |
| Rust service adapters | `native/nav_engine/src/infrastructure/` |
| Protobuf definitions | `proto/navigation.proto` |
| Build scripts | `Makefile` |
| Tests | `test/` (Dart), `native/nav_engine/` (Rust) |
| Docs | `docs/` (architecture, guides, ADRs) |

