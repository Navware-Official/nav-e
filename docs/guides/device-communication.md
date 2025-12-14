# Device Communication - Flutter Integration Guide

This guide explains how the device communication system works and how to integrate it into the Flutter UI.

> **Deep Dive:** For protocol details, see [Device Comm Crate](../rust/device-comm.md) and [Protobuf](../rust/protobuf.md).

## System Overview

The device communication system enables sending navigation data from the phone to wearable devices (watches, custom hardware) over Bluetooth Low Energy (BLE).

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
│   - Prepares route JSON                         │
│   - Handles transmission progress               │
│   - Manages retry logic                         │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ FFI Bridge (Flutter ↔ Rust)                     │
│ • prepareRouteMessage() - JSON → Protobuf       │
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

## Implementation Checklist

When adding device communication to a screen:

**1. Prerequisites**
- [ ] Ensure `DeviceCommBloc` is provided in widget tree
- [ ] Check `DevicesBloc` for connected devices
- [ ] Verify `BluetoothBloc` shows BLE is enabled

**2. UI Elements**
- [ ] Add "Send to Device" button (disabled if no devices)
- [ ] Device selection dropdown/dialog
- [ ] Progress indicator for transmission
- [ ] Success/error snackbars

**3. State Management**
- [ ] Listen to `DeviceCommBloc` states
- [ ] Update UI based on transmission progress
- [ ] Handle errors gracefully
- [ ] Reset state when done

**4. Data Preparation**
- [ ] Route data includes: waypoints, distance, duration, polyline
- [ ] Convert to JSON format expected by FFI
- [ ] Include route ID for tracking

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

## Error Handling Strategy

### User-Facing Errors

**Device Not Connected**
- **Detection:** Check `DevicesBloc.state.connectedDevices`
- **Action:** Prompt user to connect device first
- **UI:** "Please connect a device to send routes"

**Transmission Failed**
- **Detection:** `DeviceCommError` state
- **Action:** Offer retry button
- **UI:** "Failed to send route. Retry?"

**Invalid Route Data**
- **Detection:** FFI returns error
- **Action:** Log error, show generic message
- **UI:** "Unable to prepare route data"

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

### External Tools

**nRF Connect** (Android/iOS)
- View raw BLE packets
- Verify characteristic UUIDs
- Monitor transmission timing
- Check MTU negotiation

**Wireshark with Bluetooth Plugin**
- Capture BLE traffic
- Analyze protocol timing
- Debug frame structure

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

### Optimization Tips

**For UI:**
- Show progress bar for routes > 20 waypoints
- Disable button during transmission
- Use BlocBuilder to update progress smoothly

**For Data:**
- Simplify polyline before sending (Douglas-Peucker algorithm)
- Remove unnecessary waypoint metadata
- Use RouteSummary for frequent updates (lighter)

**For Reliability:**
- Wait for device connection before enabling send
- Implement retry logic (already in service layer)
- Validate route data before transmission

## Next Steps

**For Developers:**
1. Review [Device Comm Protocol](../rust/device-comm.md) for implementation details
2. Check [Protobuf Messages](../rust/protobuf.md) for message structure
3. See [Testing Guide](testing.md) for integration testing strategies

**For Testers:**
1. Use DeviceCommDebugScreen for manual testing
2. Test with various route sizes (small, medium, large)
3. Verify error handling (disconnect device mid-transmission)
4. Check UI responsiveness during long transmissions

**For Device Firmware Developers:**
1. Implement frame reassembly using FrameAssembler pattern
2. Validate CRC checksums on each frame
3. Send ACK/NACK control messages
4. Handle out-of-order frames correctly
