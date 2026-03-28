# nav_e Flutter App

The Flutter application layer: map-based navigation UI backed by a Rust core via flutter_rust_bridge FFI.

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                      app/                            │
│  main.dart  ·  app_router.dart  ·  app_shell.dart   │
└────────────────────────┬─────────────────────────────┘
                         │ BlocProvider / GoRouter
┌────────────────────────▼─────────────────────────────┐
│                     core/                            │
│  bloc/        Global BLoCs (Location, Bluetooth,     │
│               MapBloc, DeviceComm, ThemeCubit)       │
│  domain/      Entities + repository interfaces       │
│  theme/       AppSpacing · AppColors · AppElevation  │
│  device_comm/ DeviceCommunicationService (BLE)       │
│  routing/     RoutingEngineService (SharedPrefs)     │
│  nav/         NavSettingsService                     │
│  notifications/ NavNotificationService               │
└────────────────────────┬─────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────┐
│                   features/ (15)                     │
│  Each feature owns its own BLoC/Cubit, screens,      │
│  widgets, and data adapters. Data adapters call into │
│  the Rust FFI or platform services.                  │
└────────────────────────┬─────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────┐
│               bridge/  (GENERATED — do not edit)     │
│  lib.dart  ·  frb_generated.dart                    │
│  import 'package:nav_e/bridge/lib.dart' as api;      │
└──────────────────────────────────────────────────────┘
```

### Global vs scoped state

| Scope | Provider | Examples |
|---|---|---|
| App root (`main.dart`) | `BlocProvider` at `MaterialApp` level | `LocationBloc`, `BluetoothBloc`, `MapBloc`, `DeviceCommBloc`, `ThemeCubit`, `SavedPlacesCubit`, `SavedRoutesCubit`, `TripHistoryCubit`, `OfflineMapsCubit`, `PreviewCubit` |
| Route-scoped | `BlocProvider` inside route builder | `NavBloc`, `SearchBloc`, `DevicesBloc` |

### BLoC vs Cubit split

**BLoC** (event-driven; complex state machines):
- `NavBloc` — turn-by-turn navigation with off-route detection and rerouting
- `SearchBloc` — geocoding with debounce and history
- `DevicesBloc` — device CRUD via Rust FFI
- `MapBloc` — camera, polylines, map source, data layers
- `DeviceCommBloc` — BLE route/map transmission

**Cubit** (simple emit-based; list/flag state):
- `ThemeCubit`, `SavedPlacesCubit`, `SavedRoutesCubit`, `TripHistoryCubit`, `OfflineMapsCubit`, `PreviewCubit`

---

## App initialization

### Startup sequence (`main.dart`)

```
main()
 └─ RustLib.init()               // initialise flutter_rust_bridge
 └─ WidgetsFlutterBinding         // Flutter engine
 └─ _AppLoader widget
     ├─ api.initializeDatabase(dbPath)   // Rust SQLite setup
     ├─ Build RepositoryProvider tree   // 7 repository singletons
     ├─ Build BlocProvider tree         // global BLoCs + Cubits
     ├─ Check api.getActiveSession()    // restore in-progress session
     └─ NavE (MaterialApp.router)
         └─ GoRouter (app_router.dart)
```

Active session restoration: if `getActiveSession()` returns a non-null `Session`, a banner is shown offering to resume. Pending GPX imports arriving via platform channel are forwarded to `SavedRoutesCubit` before the first frame.

### Global BLoC providers (in order)

```dart
// Repositories (innermost first):
RepositoryProvider<GeocodingRepository>
RepositoryProvider<SavedPlacesRepository>
RepositoryProvider<SavedRoutesRepository>
RepositoryProvider<TripRepository>
RepositoryProvider<MapSourceRepository>
RepositoryProvider<DeviceRepository>
RepositoryProvider<OfflineRegionsRepository>

// BLoCs / Cubits:
BlocProvider<ThemeCubit>
BlocProvider<LocationBloc>
BlocProvider<BluetoothBloc>
BlocProvider<MapBloc>
BlocProvider<DeviceCommBloc>
BlocProvider<SavedPlacesCubit>
BlocProvider<SavedRoutesCubit>
BlocProvider<TripHistoryCubit>
BlocProvider<OfflineMapsCubit>
BlocProvider<PreviewCubit>
```

### Named routes (`app_router.dart`)

GoRouter with a `StatefulShellRoute` providing four indexed branches:

| Branch | Index | Root path |
|---|---|---|
| Home / Explore | 0 | `/` |
| Plan | 1 | `/plan` |
| Saved Routes | 2 | `/saved-routes` |
| Profile | 3 | `/profile` |

Top-level routes (rendered above the shell):

| Name | Path | Description |
|---|---|---|
| `activeNav` | `/active-nav` | Turn-by-turn navigation screen |
| `planRoute` | `/plan-route` | Route planning with map preview |
| `search` | `/search` | Geocoding search screen |
| `savedPlaces` | `/saved-places` | User-saved places list |
| `tripHistory` | `/trip-history` | Completed trip list |
| `tripDetail` | `/trip-detail` | Individual trip replay |
| `deviceManagement` | `/device-management` | BLE device list + pairing |
| `addDevice` | `/add-device` | New device registration |
| `offlineMaps` | `/offline-maps` | Downloaded region manager |
| `settings` | `/settings` | App settings |
| `licenses` | `/licenses` | OSS license viewer |
| `deviceCommDebug` | `/device-comm-debug` | BLE debug console (dev) |
| `importPreview` | `/import-preview` | GPX import confirmation |
| `routeFinish` | `/route-finish` | Post-navigation summary |
| `locationPreview` | `/location-preview` | Tapped-point detail sheet |

Redirect guards validate `extra` state (e.g. `/plan-route` requires a `GeocodingResult`; `/active-nav` requires a `Session`).

---

## Core infrastructure

### Global BLoCs

#### LocationBloc (`lib/core/bloc/location_bloc.dart`)

Streams GPS position, heading, and speed from the platform location API. All features that need the user's position listen to this bloc rather than subscribing to location directly.

Key state fields: `position: LatLng?`, `heading: double?`, `speed: double?`, `accuracy: double?`.

#### BluetoothBloc (`lib/core/bloc/bluetooth/`)

Manages BLE adapter state and device scan results. Consumed by `DeviceManagementScreen` and `DeviceCommBloc`.

#### MapBloc (`lib/features/map_layers/presentation/bloc/map_bloc.dart`)

Owns the MapLibre camera and overlay state shared across all screens that embed the map widget.

```dart
class MapState {
  final LatLng center;
  final double zoom;
  final double tilt;         // 0–60°; nav uses 45°
  final double bearing;
  final bool isReady;
  final bool followUser;
  final List<PolylineModel> polylines;
  final bool autoFit;
  final MapSource? source;
  final List<MapSource> available;
  final bool loadingSource;
  final Set<String> enabledDataLayerIds;
  // Optional style overrides (null = app default):
  final int? defaultPolylineColorArgb;
  final double? defaultPolylineWidth;
  final int? markerFillColorArgb;
  final int? markerStrokeColorArgb;
}
```

#### DeviceCommBloc (`lib/features/device_comm/device_comm_bloc.dart`)

Wraps `DeviceCommunicationService`. Events: `SendRouteToDevice`, `SendMapRegionToDevice`, `SendMapStyleToDevice`, `SendControlCommand`, `MessageReceived`, `ResetDeviceComm`. States: `DeviceCommIdle`, `DeviceCommSending(progress)`, `DeviceCommSuccess`, `DeviceCommError`, `MessageFromDevice`.

#### ThemeCubit (`lib/core/theme/theme_cubit.dart`)

Persists and emits `AppThemeMode` (system / light / dark). Consumed by `MaterialApp` to switch `ThemeData`.

### Domain layer

Entities live in `lib/core/domain/entities/`. Repository interfaces in `lib/core/domain/repositories/`. Concrete implementations are in each feature's `data/` directory and talk to Rust FFI via `package:nav_e/bridge/lib.dart as api`.

| Entity | Key fields |
|---|---|
| `GeocodingResult` | `id, label, lat, lon, address?` |
| `SavedPlace` | `id, label, lat, lon, icon?` |
| `SavedRoute` | `id, name, waypoints, polyline, distanceM, durationS` |
| `Trip` | `id, routeId, startedAt, endedAt, distanceM, durationS` |
| `Device` | `id, name, remoteId, type` |
| `OfflineRegion` | `id, name, bbox, zoomMin, zoomMax, tileCount` |
| `MapSource` | `id, name, tileUrl, type` |

### Theme / design system

All UI styling uses tokens from `lib/core/theme/`. Never use raw `Colors.*` in widget build methods.

#### Spacing (`lib/core/theme/spacing.dart`)

8-pt grid constants:

| Token | Value |
|---|---|
| `AppSpacing.xs` | 4 |
| `AppSpacing.sm` | 8 |
| `AppSpacing.md` | 16 |
| `AppSpacing.lg` | 24 |
| `AppSpacing.xl` | 32 |
| `AppSpacing.xxl` | 48 |

Off-grid values (6, 10, 12, 20, …) are written as literals with an `// off-grid` comment.

#### Colors (`lib/core/theme/colors.dart`)

`AppColors` is a `ThemeExtension` providing semantic tokens beyond `ColorScheme`:

| Token | Purpose |
|---|---|
| `success` / `onSuccess` | Positive confirmations |
| `warning` / `onWarning` | Speed-limit alerts, cautions |
| `info` / `onInfo` | Informational banners |
| `disabled` / `onDisabled` | Inactive controls |

Retrieve with: `Theme.of(context).extension<AppColors>()!`

#### Elevation (`lib/core/theme/elevation.dart`)

`AppElevation.level1(shadow)` through `AppElevation.level4(shadow)` return `List<BoxShadow>` following Material 3 guidelines. Pass `colorScheme.shadow` as the tint colour.

#### `app_theme.dart`

Builds `ThemeData` for light and dark modes with Material 3, custom component themes (AppBar, Card, Button, TextField, Badge, SettingsPanel), and `AppColors` registered as a `ThemeExtension`.

### Services

#### `RoutingEngineService` (`lib/core/routing/routing_engine_service.dart`)

Persists the user's preferred routing engine in `SharedPreferences`.

```dart
enum RoutingEngine { osrm, valhalla, onDevice }
// Only RoutingEngine.osrm is currently implemented.
await RoutingEngineService.setDefaultEngine(RoutingEngine.osrm);
final engine = await RoutingEngineService.getDefaultEngine();
```

#### `NavSettingsService` (`lib/core/nav/nav_settings_service.dart`)

Persists navigation preferences (voice guidance, speed-limit alerts, etc.) via `SharedPreferences`.

#### `NavNotificationService` (`lib/core/notifications/nav_notification_service.dart`)

Posts local notifications for turn instructions when the app is backgrounded during active navigation.

### Device communication

`DeviceCommunicationService` (`lib/core/device_comm/device_communication_service.dart`) is the single entry point for all BLE data transfer. It accepts a transport abstraction:

| Transport | Class | Notes |
|---|---|---|
| BLE | `BleDeviceCommunicationTransport` | Production; uses `flutter_blue_plus` |

Messages are protobuf-encoded (definitions in `lib/core/device_comm/proto/`; generated from `native/nav_protocol`). The service exposes:
- `sendRoute(remoteId, routeJson, {onProgress})` — streams route JSON over BLE
- `sendMapRegion(remoteId, regionId, {onProgress})` — streams offline tile region
- `sendMapStyle(remoteId, mapSourceId)` — sends map source configuration
- `sendControlCommand(remoteId, ...)` — sends control frames
- `messageStream` — `Stream<DeviceMessage>` for incoming device messages
- `getConnectedDeviceIds()` → `List<ConnectedDeviceInfo>`

### FFI bridge

```dart
import 'package:nav_e/bridge/lib.dart' as api;
```

`lib/bridge/` is **generated** by `make codegen` from `native/nav_e_ffi/src/lib.rs`. Never edit it manually. Key callable functions:

| Function | Returns | Purpose |
|---|---|---|
| `api.initializeDatabase(dbPath)` | `void` | One-time DB setup at startup |
| `api.getActiveSession()` | `String?` (JSON) | Restore in-progress nav session |
| `api.startNavigationSession(waypoints, pos)` | `String` (JSON) | Create Rust nav session |
| `api.updateNavigationPosition(sessionId, lat, lon)` | `String` (JSON) | Feed GPS → nav engine → state |
| `api.getNavigationState(sessionId)` | `String?` (JSON) | Poll current navigation state |
| `api.getRouteSteps(sessionId)` | `String` (JSON) | Full step list for turn feed |
| `api.stopNavigation(sessionId)` | `void` | End session, persist trip |
| `api.pauseNavigation(sessionId)` | `void` | Pause session |
| `api.resumeNavigation(sessionId)` | `void` | Resume session |
| `api.calculateRoute(waypoints, engine)` | `String` (JSON) | OSRM route calculation |
| `api.saveTrip(...)` | `void` | Persist completed trip |

---

## Features

### `device_comm` — BLE Debug Console

**Pattern:** BLoC (`DeviceCommBloc`)
**Purpose:** Developer-facing screen for inspecting raw BLE message exchange with connected devices. Not exposed in production navigation flows.

**State shape:** see `DeviceCommBloc` in Core section above.

**Key files:**
- `lib/features/device_comm/device_comm_bloc.dart`
- `lib/features/device_comm/presentation/screens/device_comm_debug_screen.dart`
- `lib/features/device_comm/presentation/bloc/device_comm_events.dart`
- `lib/features/device_comm/presentation/bloc/device_comm_states.dart`

---

### `device_management` — BLE Device Registry

**Pattern:** BLoC (`DevicesBloc`)
**Purpose:** Lists paired BLE navigation devices, supports adding and removing devices. Each device can receive routes and offline map regions over BLE.

**State shape:**

```dart
sealed class DevicesState
class DeviceInitial      extends DevicesState
class DeviceLoadInProgress extends DevicesState
class DeviceLoadSuccess  extends DevicesState { List<Device> devices }
class DeviceOperationInProgress extends DevicesState
class DeviceOperationSuccess extends DevicesState { String message; Device? device }
class DeviceOperationFailure extends DevicesState { String message }
```

**FFI calls:** `api.getDevices()`, `api.addDevice(...)`, `api.removeDevice(id)`

**Key files:**
- `lib/features/device_management/bloc/devices_bloc.dart`
- `lib/features/device_management/device_management_screen.dart`
- `lib/features/device_management/add_device_screen.dart`
- `lib/features/device_management/data/device_repository_rust.dart`

---

### `home` — Explore Map Shell

**Pattern:** StatefulWidget (no dedicated BLoC; reads global `MapBloc`, `LocationBloc`, `PreviewCubit`)
**Purpose:** The main explore view with a MapLibre map, a floating search bar, a side-menu drawer, and a location-preview bottom sheet. Acts as a compositing layer for `map_layers`, `location_preview`, and `search` overlays.

**Key files:**
- `lib/features/home/home_screen.dart`
- `lib/features/home/home_view.dart`
- `lib/features/home/dashboard/home_dashboard_screen.dart`
- `lib/features/home/widgets/search_overlay_widget.dart`
- `lib/features/home/widgets/route_preview_widget.dart`
- `lib/features/home/utils/route_params_handler.dart`

---

### `location_preview` — Tapped-Point Detail

**Pattern:** Cubit (`PreviewCubit`)
**Purpose:** Shows a bottom sheet with details about a map-tapped coordinate or a resolved geocoding result. Provides quick actions (save place, navigate here, route from here).

**State shape:**

```dart
sealed class PreviewState
class PreviewIdle               extends PreviewState
class LocationPreviewShowing    extends PreviewState { GeocodingResult result }
```

**API:**

```dart
context.read<PreviewCubit>().showCoords(lat: ..., lon: ..., label: ...);
context.read<PreviewCubit>().showResolved(result);
context.read<PreviewCubit>().hide();
```

**Key files:**
- `lib/features/location_preview/cubit/preview_cubit.dart`
- `lib/features/location_preview/location_preview_widget.dart`
- `lib/features/location_preview/data/preview_params_mapper.dart`

---

### `map_layers` — Map Rendering & Camera

**Pattern:** BLoC (`MapBloc`)
**Purpose:** Owns the MapLibre widget lifecycle, camera control (follow-user, tilt, bearing, auto-fit), polyline overlays, map source switching, and data layer toggles (e.g. parking overlay). All other features write to `MapBloc` and read the shared `MapState`.

**Key events:** `MapReady`, `MoveTo`, `SetFollowUser`, `SetPolylines`, `SetTilt`, `SetBearing`, `ResetBearing`, `SetMapSource`, `ToggleDataLayer`, `SetStyleOverrides`

**Key files:**
- `lib/features/map_layers/presentation/bloc/map_bloc.dart`
- `lib/features/map_layers/presentation/map_widget.dart`
- `lib/features/map_layers/presentation/map_adapters/maplibre_widget.dart`
- `lib/features/map_layers/presentation/map_adapters/maplibre_map_adapter.dart`
- `lib/features/map_layers/data/data_layer_registry.dart`
- `lib/features/map_layers/models/polyline_model.dart`

---

### `nav` — Active Turn-by-Turn Navigation

**Pattern:** BLoC (`NavBloc`)
**Purpose:** Manages an active navigation session from start to finish. Feeds GPS positions into the Rust nav engine, receives `NavigationStateDto` back (snapped position, next cue, remaining distance/time, constraint alerts), debounces off-route detection (3-strike threshold, 30 s cooldown), and triggers automatic rerouting.

**Events:**

| Event | Trigger |
|---|---|
| `NavStart(routeId, routePoints, sessionId?)` | User confirms route in `PlanRouteScreen` |
| `NavStop({completed})` | User taps finish or route completes |
| `PositionUpdate(position, speed?, bearing?)` | `LocationBloc` stream |
| `CueFromNative(cue)` | Rust nav engine pushes a new turn instruction |
| `SetFollowMode(follow)` | User taps recenter FAB |
| `SetTurnFeed(feed)` | Full step list refresh from `getRouteSteps` |
| `NavPause` | User taps pause button |
| `NavResume` | User taps resume button |
| `NavReroute` | Off-route debouncer fires |

**State shape:**

```dart
class NavState {
  final bool active;
  final String? routeId;
  final String? sessionId;          // Rust session ID for FFI calls
  final double? remainingDistanceM;
  final int? remainingSeconds;
  final NavCue? nextCue;
  final List<LatLng> progressPolyline;
  final List<NavCue> turnFeed;
  final double? speed;
  final LatLng? lastPosition;
  final bool following;
  final bool lightweightMode;
  final DateTime? startedAt;
  final double? distanceM;
  final int? durationS;
  final String? destinationLabel;
  final bool completedWithSummary;
  final bool isOffRoute;
  final bool isPaused;
  final bool isRerouting;
  final List<String> constraintAlerts;  // e.g. speed limit warnings
  final LatLng? snappedPosition;        // route-snapped GPS for map puck
}
```

**FFI calls:** `startNavigationSession`, `updateNavigationPosition`, `getRouteSteps`, `stopNavigation`, `pauseNavigation`, `resumeNavigation`, `calculateRoute` (reroute), `saveTrip`

**Key files:**
- `lib/features/nav/bloc/nav_bloc.dart`
- `lib/features/nav/bloc/nav_event.dart`
- `lib/features/nav/bloc/nav_state.dart`
- `lib/features/nav/ui/active_nav_screen.dart`
- `lib/features/nav/ui/nav_banner.dart`
- `lib/features/nav/ui/route_finish_screen.dart`
- `lib/features/nav/models/nav_models.dart`

---

### `offline_maps` — Tile Region Manager

**Pattern:** Cubit (`OfflineMapsCubit`)
**Purpose:** Lists, downloads, and deletes offline map tile regions. Download iterates over predefined zoom levels and reports per-tile progress. A local tile server (`LocalTileServer`) serves cached tiles to the map renderer.

**State shape:**

```dart
enum OfflineMapsStatus { initial, loading, loaded, downloading, error }

class OfflineMapsState {
  final OfflineMapsStatus status;
  final List<OfflineRegion> regions;
  final String? errorMessage;
  final int downloadProgress;       // tiles downloaded so far
  final int downloadTotal;          // total tiles for this zoom level
  final int downloadZoom;           // current zoom level being fetched
  final String? downloadingRegionName;
}
```

**FFI calls:** `api.listOfflineRegions()`, `api.downloadOfflineRegion(...)`, `api.deleteOfflineRegion(id)`

**Key files:**
- `lib/features/offline_maps/cubit/offline_maps_cubit.dart`
- `lib/features/offline_maps/cubit/offline_maps_state.dart`
- `lib/features/offline_maps/presentation/offline_maps_screen.dart`
- `lib/features/offline_maps/presentation/widgets/download_region_sheet.dart`
- `lib/features/offline_maps/data/local_tile_server.dart`
- `lib/features/offline_maps/data/predefined_regions.dart`

---

### `plan` — Quick Navigation Start

**Pattern:** StatelessWidget / StatefulWidget (reads global state)
**Purpose:** The "Plan" tab of the bottom navigation shell. Provides a quick-start UI with recent searches, saved places shortcuts, and a "Go" button that transitions to `PlanRouteScreen` with a prefilled destination.

**Key files:**
- `lib/features/plan/plan_screen.dart`

---

### `plan_route` — Route Planning & Preview

**Pattern:** StatefulWidget + inline route calculation (no dedicated BLoC)
**Purpose:** Full route planning screen. Users select a start point (GPS, map centre, or manual pick), select a destination (passed as `GeocodingResult` via router `extra`), choose a routing engine, and preview the resulting polyline on the map. Debounced recalculation (400 ms) fires on any input change. Users can save the route or start navigation.

**FFI calls:** `api.calculateRoute(waypoints, engine)` → JSON with polyline, distanceM, durationS

**Key files:**
- `lib/features/plan_route/plan_route_screen.dart`
- `lib/features/plan_route/widgets/route_top_panel.dart`
- `lib/features/plan_route/widgets/route_bottom_sheet.dart`
- `lib/features/plan_route/widgets/plan_route_map.dart`

---

### `profile` — User Profile

**Pattern:** StatelessWidget
**Purpose:** Displays user account information and provides navigation links to settings, trip history, saved places, and saved routes. Entry point for account-level management.

**Key files:**
- `lib/features/profile/profile_screen.dart`

---

### `saved_places` — Bookmarked Locations

**Pattern:** Cubit (`SavedPlacesCubit`)
**Purpose:** CRUD for user-bookmarked locations. Loaded at startup and kept live so place counts are reflected across the app.

**State shape:**

```dart
sealed class SavedPlacesState
class SavedPlacesInitial extends SavedPlacesState
class SavedPlacesLoading extends SavedPlacesState
class SavedPlacesLoaded  extends SavedPlacesState { List<SavedPlace> places }
class SavedPlacesError   extends SavedPlacesState { String message }
```

**FFI calls:** `api.getSavedPlaces()`, `api.savePlace(...)`, `api.deletePlace(id)`

**Key files:**
- `lib/features/saved_places/cubit/saved_places_cubit.dart`
- `lib/features/saved_places/cubit/saved_places_state.dart`
- `lib/features/saved_places/saved_places_screen.dart`
- `lib/features/saved_places/data/saved_places_repository_rust.dart`

---

### `saved_routes` — Route Library

**Pattern:** Cubit (`SavedRoutesCubit`)
**Purpose:** Lists routes saved from `PlanRouteScreen` or imported as GPX files. Each `SavedRoute` is paired with a `RouteEnrichment` (computed metadata such as elevation gain) on load. GPX import preview is handled by `ImportPreviewScreen` before persisting.

**State shape:**

```dart
sealed class SavedRoutesState
class SavedRoutesInitial extends SavedRoutesState
class SavedRoutesLoading extends SavedRoutesState
class SavedRoutesLoaded  extends SavedRoutesState {
  List<SavedRoute> routes;
  List<RouteEnrichment> enrichments;
}
class SavedRoutesError   extends SavedRoutesState { String message }
```

**FFI calls:** `api.getSavedRoutes()`, `api.saveRoute(...)`, `api.deleteRoute(id)`, `api.importGpx(xml)`

**Key files:**
- `lib/features/saved_routes/cubit/saved_routes_cubit.dart`
- `lib/features/saved_routes/cubit/saved_routes_state.dart`
- `lib/features/saved_routes/saved_routes_screen.dart`
- `lib/features/saved_routes/import_preview_screen.dart`
- `lib/features/saved_routes/route_enrichment.dart`
- `lib/features/saved_routes/data/saved_routes_repository_rust.dart`

---

### `search` — Geocoding

**Pattern:** BLoC (`SearchBloc`)
**Purpose:** Full-screen search with debounced geocoding via Nominatim (through the Rust `nav_route` crate), search history, and result selection. Selected `GeocodingResult` is passed as `extra` to the router when navigating to `PlanRouteScreen`.

**State shape:**

```dart
class SearchState {
  final bool loading;
  final List<GeocodingResult> results;
  final List<GeocodingResult> history;
  final String? error;
  final GeocodingResult? selected;
}
```

**FFI calls:** `api.geocode(query)` → JSON list of `GeocodingResult`

**Key files:**
- `lib/features/search/bloc/search_bloc.dart`
- `lib/features/search/bloc/search_event.dart`
- `lib/features/search/bloc/search_state.dart`
- `lib/features/search/search_screen.dart`
- `lib/features/search/data/geocoding_repository_frb_typed_impl.dart`

---

### `settings` — App Settings

**Pattern:** StatelessWidget (reads service singletons + `ThemeCubit` + `OfflineMapsCubit`)
**Purpose:** Aggregates all user preferences across themed sections:

| Section | Widget | Controls |
|---|---|---|
| Theme | `ThemeSettingsSection` | Light / Dark / System toggle |
| Routing engine | `RoutingEngineSettingsSection` | OSRM / Valhalla / On-Device (OSRM only active) |
| Navigation | `NavigationSettingsSection` | Voice guidance, speed alerts |
| Map styling | `MapStylingSection` | Map source picker |
| Offline maps | `OfflineMapsSectionWidget` | Quick link to offline map manager |
| Trip history | `TripHistorySettingsSection` | Clear history |
| About | `AboutSection` | Version, licenses |

**Key files:**
- `lib/features/settings/settings_screen.dart`
- `lib/features/settings/widgets/` (one file per section)

---

### `trip_history` — Completed Trips

**Pattern:** Cubit (`TripHistoryCubit`)
**Purpose:** Lists completed navigation sessions. Each `Trip` can be opened in `TripDetailScreen` for a replay of the route polyline.

**State shape:**

```dart
abstract class TripHistoryState
class TripHistoryInitial extends TripHistoryState
class TripHistoryLoading extends TripHistoryState
class TripHistoryLoaded  extends TripHistoryState { List<Trip> trips }
class TripHistoryError   extends TripHistoryState { String message }
```

**FFI calls:** `api.getTrips()`, `api.deleteTrip(id)`

**Key files:**
- `lib/features/trip_history/cubit/trip_history_cubit.dart`
- `lib/features/trip_history/cubit/trip_history_state.dart`
- `lib/features/trip_history/trip_history_screen.dart`
- `lib/features/trip_history/trip_detail_screen.dart`
- `lib/features/trip_history/data/trip_repository_rust.dart`

---

## Data flows

### 1. End-to-end navigation

```
User taps "Go" in PlanScreen / SavedRoutes
    │
    ▼
SearchScreen (if destination not yet set)
  SearchBloc calls api.geocode(query)
  User selects GeocodingResult
    │
    ▼
PlanRouteScreen
  api.calculateRoute(waypoints, engine="osrm")
  MapBloc ← SetPolylines([routePolyline])
  MapBloc ← SetTilt(45), SetFollowUser(true)
  User taps "Start Navigation"
    │
    ▼
api.startNavigationSession(waypoints, currentPosition)
  → returns sessionId (JSON)
NavBloc ← NavStart(routeId, routePoints, sessionId: sessionId)
  → push /active-nav
    │
    ▼ (every GPS tick from LocationBloc)
NavBloc ← PositionUpdate(position, speed, bearing)
  api.updateNavigationPosition(sessionId, lat, lon)
  → NavigationStateDto { snappedPosition, nextInstruction,
                         distanceToNextM, distanceRemainingM,
                         etaSeconds, offRoute, constraintAlerts }
  NavBloc emits NavState (nextCue, remainingDistanceM, …)
  MapBloc ← MoveTo(snappedPosition) [camera follow]
  NavBanner redraws turn instruction + distance
    │
    ▼ (off-route: 3 consecutive ticks)
NavBloc ← NavReroute
  api.calculateRoute(from=snappedPosition, to=destination)
  api.startNavigationSession(…) [new sessionId]
  NavBloc updates sessionId, polyline
    │
    ▼ (destination reached or user taps Finish)
NavBloc ← NavStop(completed: true)
  api.stopNavigation(sessionId)
  api.saveTrip(…)
  TripHistoryCubit reloads
  router.push('/route-finish', extra: RouteFinishPayload)
```

### 2. Offline map download

```
User opens OfflineMapsScreen
  OfflineMapsCubit.load() → api.listOfflineRegions()
  renders list of OfflineRegion tiles
    │
    ▼ (user taps "Download Region")
DownloadRegionSheet / SelectRegionSheet displayed
  User selects predefined region (PredefinedRegions.all)
    │
    ▼
OfflineMapsCubit.download(region)
  emits OfflineMapsState(status: downloading, downloadingRegionName: ...)
  for each zoom level:
    api.downloadOfflineRegion(id, bbox, zoom,
        onProgress: (done, total) {
          emit state.copyWith(downloadProgress: done, downloadTotal: total,
                              downloadZoom: zoom);
        })
  emits status: loaded
  LocalTileServer registers new region for offline map rendering
```

### 3. Settings → routing engine change

```
User opens SettingsScreen → RoutingEngineSettingsSection
  reads current engine via RoutingEngineService.getDefaultEngine()
  renders radio list (OSRM active; Valhalla/On-Device show "Coming soon")
    │
    ▼ (user selects OSRM)
RoutingEngineService.setDefaultEngine(RoutingEngine.osrm)
  SharedPreferences.setString('routing_engine', 'osrm')
    │
    ▼ (next route calculation in PlanRouteScreen)
api.calculateRoute(waypoints, engine: 'osrm')
```

---

## App layout

```
lib/
├── main.dart                          # App entry point; DB init, providers, session restore
├── app/
│   ├── app_nav.dart                   # Navigation helpers
│   ├── app_router.dart                # GoRouter: shell + all named routes
│   └── app_shell.dart                 # StatefulShellRoute scaffold
├── bridge/                            # GENERATED — do not edit
│   ├── frb_generated.dart
│   ├── frb_generated.io.dart
│   └── lib.dart                       # Public FFI surface (import as api)
├── core/
│   ├── bloc/
│   │   ├── location_bloc.dart
│   │   └── bluetooth/                 # BluetoothBloc + events/states
│   ├── constants/
│   │   └── app_version.dart
│   ├── data/
│   │   ├── map_adapter.dart
│   │   └── remote/                    # Remote map source configs
│   ├── device_comm/
│   │   ├── device_communication_service.dart
│   │   ├── ble_device_comm_transport.dart
│   │   └── proto/                     # Dart protobuf generated files
│   ├── domain/
│   │   ├── entities/                  # GeocodingResult, Device, Trip, …
│   │   ├── extensions/
│   │   └── repositories/              # Abstract repository interfaces
│   ├── nav/
│   │   └── nav_settings_service.dart
│   ├── notifications/
│   │   └── nav_notification_service.dart
│   ├── platform/
│   │   └── route_import_channel.dart  # GPX import platform channel
│   ├── routing/
│   │   └── routing_engine_service.dart
│   └── theme/
│       ├── app_theme.dart             # ThemeData builders (light + dark)
│       ├── colors.dart                # AppColors ThemeExtension
│       ├── elevation.dart             # AppElevation.level1–4
│       ├── spacing.dart               # AppSpacing constants
│       ├── palette.dart               # Raw colour palette (theme use only)
│       ├── typography.dart            # TextTheme definitions
│       ├── theme_cubit.dart
│       └── components/
│           ├── appbar.dart
│           ├── badges.dart
│           ├── buttons.dart
│           ├── cards.dart
│           ├── decorations.dart
│           ├── inputs.dart
│           └── settings_panel.dart
├── features/
│   ├── device_comm/                   # BLE debug console
│   ├── device_management/             # BLE device registry
│   ├── home/                          # Explore map shell + overlays
│   ├── location_preview/              # Tapped-point detail sheet
│   ├── map_layers/                    # MapBloc + MapLibre widget
│   ├── nav/                           # Active turn-by-turn navigation
│   ├── offline_maps/                  # Tile region download/manage
│   ├── plan/                          # Quick navigation start tab
│   ├── plan_route/                    # Route planning + preview
│   ├── profile/                       # User profile tab
│   ├── saved_places/                  # Bookmarked locations
│   ├── saved_routes/                  # Route library + GPX import
│   ├── search/                        # Geocoding search screen
│   ├── settings/                      # App settings
│   └── trip_history/                  # Completed trips
└── widgets/                           # Shared leaf widgets
    ├── draggable_fab_widget.dart
    ├── search_bar_widget.dart
    ├── side_menu_drawer.dart
    ├── user_location_marker.dart
    └── subtext.widget.dart
```
