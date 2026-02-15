# Device Communication - Flutter Integration Guide

This guide explains how the device communication system works and how to integrate it into the Flutter UI.

> **Deep Dive:** For protocol details, see [Device Comm Crate](../rust/device-comm.md) and [Protobuf](../rust/protobuf.md).

## System Overview

The device communication system enables sending navigation data from the phone to wearable devices (watches, custom hardware).

### Prototype: Wear OS Message API (Android)

For the **prototype**, phone–watch communication on Android uses the **Wear OS Message API** over the existing Wear OS companion link (no BLE scan or GATT). This avoids connection popups and conflicts with the Wear OS companion. The same protobuf messages and frame format are used; only the transport changes.

- **Phone (nav-e):** MethodChannel `org.navware.nav_e/wear` (`getConnectedNodes`, `sendFrames`); EventChannel `org.navware.nav_e/wear_messages` for incoming messages from the watch.
- **Paths:** Phone → watch: `/nav/frame` (one BLE-style frame per Wear message). Watch → phone: `/nav/msg` (e.g. ACK).
- **Later versions** will switch back to BLE; the transport is abstracted so only the injected implementation (Wear vs BLE) changes.

**Connecting to another phone:** The Wear OS transport only works for **phone (nav-e) ↔ Wear OS watch (nav-c)**. It does not support connecting to a second phone. To connect to another phone (e.g. a second Android device running nav-c as a GATT server), use **BLE**: in `main.dart` inject `BleDeviceCommTransport()` instead of `WearDeviceCommTransport()` on Android (or add a setting/build flag to choose transport). Then the phone will scan for BLE devices and can connect to the other phone.

### Production: BLE

Production and non-Android builds use **Bluetooth Low Energy (BLE)** to send data to wearables (watches, custom hardware).

### Architecture Layers

```
┌─────────────────────────────────────────────────┐
│ Flutter UI Layer                                │
│ • PlanRouteScreen with "Send to Device" button │
│ • DeviceCommDebugScreen for testing            │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ State Management (BLoC Pattern)                 │
│ • DeviceCommBloc - Send routes & commands       │
│ • DevicesBloc - Connected devices list          │
│ • BluetoothBloc - BLE connection management     │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ Service Layer (Business Logic)                  │
│ • DeviceCommunicationService                    │
│   - Prepares route JSON & map region messages   │
│   - Handles transmission progress               │
│   - Manages retry logic                         │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ FFI Bridge (Flutter ↔ Rust)                     │
│ • prepareRouteMessage() - JSON → Protobuf       │
│ • getOfflineRegionTileList/Bytes, prepare*      │
│ • chunkMessageForBle() - Split into frames      │
│ • createControlMessage() - Commands             │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ Rust Native Layer                               │
│ • device_comm crate - Frame chunking & CRC      │
│ • nav_engine - Business logic & routing         │
│ • Protobuf serialization                        │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ BLE Transport (flutter_blue_plus)               │
│ • GATT characteristic writes                    │
│ • MTU negotiation (247-517 bytes)              │
│ • Connection management                         │
└─────────────────────────────────────────────────┘
```

## Key Components

### 1. DeviceCommBloc - State Management

**Purpose:** Coordinates device communication and manages UI state.

**Key Events:**
- `SendRouteToDevice` - Triggers route transmission
- `SendMapRegionToDevice` - Sends an offline map region (metadata + tile chunks) to the device
- `SendMapStyleToDevice` - Sends current map source id so the device shows the same map style
- `SendControlCommand` - Sends commands (START_NAV, STOP_NAV, ACK)
- `MessageReceived` - Handles incoming device messages
- `ResetDeviceComm` - Clears state

**Key States:**
- `DeviceCommIdle` - Ready to send
- `DeviceCommSending(progress)` - Transmission in progress
- `DeviceCommSuccess` - Completed successfully
- `DeviceCommError(message)` - Failed with error

### 2. DeviceCommunicationService - Business Logic

**Purpose:** Handles the mechanics of sending data over BLE.

**Responsibilities:**
1. Converts route data to protobuf format via FFI
2. Chunks messages for BLE transmission
3. Discovers correct BLE characteristic
4. Transmits frames with progress tracking
5. Implements retry logic (3 attempts with exponential backoff)

**Key Methods:**
- `sendRoute()` - Complete route transmission
- `sendMapRegion()` - Sends a downloaded offline region: metadata message first, then one TileChunk per tile, with optional progress callback
- `sendMapStyle()` - Sends current map source id (MapStyle protobuf) so nav-c can apply the same map style
- `sendControlCommand()` - Quick commands
- `_sendFramesWithRetry()` - Reliable transmission

### 3. Rust Native Layer - Protocol Implementation

**Purpose:** Low-level protocol handling that's performance-critical.

**What happens in Rust:**
1. **Protobuf Serialization** - Converts route to binary format (~10KB)
2. **Frame Chunking** - Splits into BLE-sized chunks (207 bytes each)
3. **CRC Validation** - Adds checksums to detect corruption
4. **Metadata** - Sequence numbers, route IDs, frame counts

**Why Rust?** Performance, memory safety, and cross-platform compatibility.

## How Data Flows

### Sending a Route to a Device

```
1. User Action
   └─ Taps "Send to Device" button in PlanRouteScreen

2. BLoC Event
   └─ DeviceCommBloc receives SendRouteToDevice event
      └─ Checks if device is connected
      └─ Validates route data

3. Service Layer
   └─ DeviceCommunicationService.sendRoute()
      └─ Prepares route JSON (waypoints, distance, polyline)
      └─ Calls FFI: prepareRouteMessage(routeJson)

4. Rust Processing
   └─ Parses JSON and converts to Protobuf
   └─ Chunks into frames (e.g., 73 frames for large route)
   └─ Adds CRC checksums to each frame

5. BLE Transmission
   └─ Finds writable characteristic on device
   └─ Sends frames sequentially
   └─ Updates progress (frame N of M)
   └─ Retries on failure

6. UI Feedback
   └─ BLoC emits DeviceCommSending states
   └─ UI shows progress bar
   └─ Success/error notifications
```

### Message Types

**Routes:**
- `RouteBlob` - Complete route with waypoints and geometry
- `RouteSummary` - Quick updates (next turn, ETA, distance)

**Control:**
- `START_NAV` - Begin navigation on device
- `STOP_NAV` - End navigation
- `ACK/NACK` - Acknowledgments
- `HEARTBEAT` - Keep-alive signal

**Status:**
- `PositionUpdate` - GPS location from device
- `BatteryStatus` - Device battery level
- `DeviceCapabilities` - Screen size, features

**Map data (offline regions):**
- `MapRegionMetadata` - Sent first: region id, name, bbox (n/s/e/w), zoom range, `total_tiles`. The device uses this to allocate or reset a cache and know how many tile messages to expect.
- `TileChunk` - One vector tile: `region_id`, `z`, `x`, `y`, and raw `.pbf` bytes. The phone sends one message per tile after the metadata.

Map transfer is **push** from phone to device: the phone sends metadata then each tile as `TileChunk` over BLE (chunked with the same frame protocol as routes). The **device** is responsible for reassembling frames, handling `MapRegionMetadata` and `TileChunk`, caching tiles (e.g. by `region_id`, z, x, y), and rendering (e.g. MapLibre or a custom vector renderer). This is not implemented in nav-e; the phone side only sends the data in the format the device will need.

## Integration Examples

### Basic: Send Route After Calculation

```dart
// After calculating a route in PlanRouteScreen
context.read<DeviceCommBloc>().add(
  SendRouteToDevice(
    remoteId: selectedDevice.remoteId,
    routeJson: jsonEncode(routeData),
  ),
);
```

### Advanced: Monitor Progress

```dart
BlocListener<DeviceCommBloc, DeviceCommState>(
  listener: (context, state) {
    if (state is DeviceCommSending) {
      showProgressDialog(progress: state.progress);
    } else if (state is DeviceCommSuccess) {
      showSuccessSnackbar();
    }
  },
  child: YourScreen(),
)
```

## Device Connection Lifecycle

Understanding the complete flow from device discovery to route transmission:

### Phase 1: Discovery & Connection

```
User Opens App
    ↓
BluetoothBloc checks permissions
    ↓
Starts BLE scanning
    ↓
DevicesBloc populates device list
    ↓
User selects device from list
    ↓
BluetoothBloc initiates connection
    ↓
Device added to "connected devices"
```

### Phase 2: Route Transmission

```
User calculates route
    ↓
Taps "Send to Device"
    ↓
DeviceCommBloc validates connection
    ↓
Service prepares & chunks data
    ↓
Frames sent over BLE (with progress)
    ↓
Success/error feedback to user
```

### Map region transfer (offline maps)

From the **Offline maps** screen, each region has a "Send to device" action. The flow:

1. User taps send icon on a region → bottom sheet lists saved devices.
2. User picks a device → `SendMapRegionToDevice(remoteId, regionId)` is dispatched.
3. Service fetches region JSON and tile list from Rust, builds `MapRegionMetadata` (with `total_tiles`), chunks and sends it.
4. For each tile (z, x, y), service reads tile bytes, builds `TileChunk`, chunks and sends. Progress callback reports (tilesSent, totalTiles).
5. Device must implement: receive and reassemble frames, handle `MapRegionMetadata` (allocate cache for `region_id`), store each `TileChunk` in cache, and use cached tiles for rendering.

### Phase 3: Navigation Session

```
Send START_NAV command
    ↓
Device displays turn-by-turn
    ↓
Periodic updates (position, ETA)
    ↓
Send STOP_NAV when complete
```

## Common Patterns

### Pattern 1: Send After Route Calculation

Used in `PlanRouteScreen` - send route immediately after calculation.

**When:** User has just calculated a route and wants to send it.
**BLoCs:** DeviceCommBloc, DevicesBloc
**Flow:** Calculate → Select device → Send → Show progress

### Pattern 2: Send from Saved Routes

Used in route history/favorites - send a previously saved route.

**When:** User selects a saved route to send.
**BLoCs:** DeviceCommBloc, DevicesBloc, RouteHistoryBloc
**Flow:** Load route → Select device → Send

### Pattern 3: Debug/Test Transmission

Used in `DeviceCommDebugScreen` - test communication with detailed logging.

**When:** Developer or tester needs to verify device communication.
**BLoCs:** DeviceCommBloc, DevicesBloc, BluetoothBloc
**Flow:** Select device → Show route info → Send → Display events

### Pattern 4: Map style on device (dropdown in map overlay)

In the map overlay options (map controls bottom sheet), a **"Map style on device"** dropdown lets the user choose which map style to send to the connected device (nav-c). This does not change the app’s own map source; it only sends the selected style to the device so nav-c can show that map. The device persists the id and applies the style; MapActivity observes the preference and updates the map.

**When:** User opens map controls (FAB) → "Map style on device" section → selects a map source from the dropdown.
**Flow:** SendMapStyleToDevice(remoteId, mapSourceId) → DeviceCommunicationService.sendMapStyle() → BLE frames.

### Developer-Facing Errors

Check logs for detailed diagnostics:
- Flutter logs: Service layer errors, BLoC state changes
- Rust logs: FFI calls, protobuf serialization, frame chunking
- BLE logs: Connection issues, characteristic discovery

## Testing & Debugging

### Built-in Debug Screen

Navigate to `/device-comm-debug` to access the debugging interface:

**Features:**
- Device selector with connection status
- Route information display (waypoints, distance, duration)
- Real-time transmission state
- Event log with timestamps
- Manual send buttons for testing

**Usage:**
```dart
context.go('/device-comm-debug', extra: routePoints);
```

### Log Monitoring

**Flutter Layer:**
```bash
flutter logs | grep -E "DeviceComm|Sending route"
```
Shows: BLoC events, service calls, progress updates

**Rust Layer:**
```bash
adb logcat | grep -E "RUST|OSRM|device_comm"
```
Shows: FFI calls, protobuf serialization, frame chunking

**BLE Layer:**
```bash
adb logcat | grep -E "BlueDevice|flutter_blue"
```
Shows: Connection events, characteristic discovery, GATT writes

### Troubleshooting Guide

| Symptom | Likely Cause | Solution |
|---------|-------------|----------|
| Button disabled | No devices connected | Connect device via BluetoothBloc |
| Immediate error | Invalid route data | Check route JSON structure |
| Progress stuck at 0% | BLE write failed | Verify characteristic is writable |
| Progress stops mid-way | Connection dropped | Check BLE signal strength |
| Success but device shows nothing | Wrong characteristic | Verify device protocol version |
| Slow transmission | Low MTU | Negotiate higher MTU (BLE 5.0+) |

## Performance Considerations

### Transmission Time Estimates

**Small Route (10 waypoints, ~2KB):**
- Chunks: ~10 frames
- Time: ~1 second
- Best for: Quick updates, test routes

**Medium Route (50 waypoints, ~8KB):**
- Chunks: ~40 frames
- Time: ~4 seconds
- Best for: City navigation

**Large Route (100 waypoints, ~15KB):**
- Chunks: ~73 frames
- Time: ~7 seconds
- Best for: Long highway trips
