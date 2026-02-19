# Bluetooth Communication Plan: nav-e ↔ nav-c-prototype

## Overview
Planning pairing and communication for demo device. For demo purposes we will use a fixed device ID pre-connected with a device name. This will allow us to skip the pairing process and focus on demonstrating the communication flow.

During the demo, a user sees the onboarding screen which shows the current status of the connection to the demo device. Once the connection is established, the user can proceed to the next fragment.

## Communication Architecture

### Phase 1: Device Discovery & Connection

#### 1.1 Initial Setup (nav-e side) — *partially done*
- **Pre-configure demo device**: Add fixed device UUID and name to nav-e configuration — *not done (no demo-specific config)*
- **Bluetooth service UUID**: Use the existing `navwareBluetoothServiceUUIDs` or define a new one for the prototype — *done* (UUID in `lib/core/bloc/bluetooth/bluetooth_bloc.dart`)
- **Connection flow**:
  1. Check Bluetooth permissions (`CheckBluetoothRequirements`) — *done*
  2. Start scanning for the demo device (`StartScanning`) — *done*
  3. Filter for specific device name/UUID — *not done* (`withServices` is commented out; no name filter)
  4. Auto-connect when found (`ToggleConnection`) — *not done* (user selects from scan list and connects manually)

#### 1.2 Onboarding Screen (nav-c-prototype side) — *done*
- **Display connection status** in `OnboardingActivity` — *done* (via `OnboardingFragment2` + `BluetoothConnectionService`)
- **Monitor Bluetooth state** using existing `bluetoothStateReceiver` — *done* (`OnboardingActivity` registers receiver for `ACTION_STATE_CHANGED`, `ACTION_CONNECTION_STATE_CHANGED`, etc.)
- **Show pairing status** when nav-e connects — *done* (`ConnectionState.Connected(deviceName, address)`, "✓ Connected to …")
- **Additional states to handle**:
  - Bluetooth disabled → Show enable prompt — *done*
  - Waiting for nav-e connection → Show spinner — *done* (Scanning/Connecting)
  - Connected → Show device name and "Ready" indicator — *done*
  - Connection lost → Show reconnection UI — *done* (Error + Retry; state updates on disconnect)

### Phase 2: Message Protocol Implementation

#### 2.1 Protobuf Message Types

**Architecture Overview:**
The protobuf messages are defined in `proto/navigation.proto` and handled differently on each platform:
- **nav-e (Flutter/Rust)**: Rust handles protobuf serialization via `prost`, exposed through FFI
- **nav-c-prototype (Android/Kotlin)**: Will use Kotlin protobuf-lite for deserialization

**Available Message Types** (from `proto/navigation.proto`):

**For testing (Step 1):**
- `Control` with `ControlType.HEARTBEAT` - Test connectivity
  - Fields: `header`, `type`, `route_id`, `status_code`, `message_text`, `seq_no`
- `DeviceCapabilities` - Send device info from nav-c
  - Fields: `device_id`, `firmware_version`, `supports_vibration`, `supports_voice`, `screen_width_px`, `screen_height_px`, `battery_level_pct`, `low_power_mode`

**For route transmission (Step 2):**
- `RouteBlob` - Full route with waypoints, legs, and polyline
  - Contains: `route_id` (UUID), `waypoints[]`, `legs[]`, `polyline_data` (encoded or raw), `metadata`, `checksum`
- `RouteSummary` - Quick route overview (distance, duration, ETA)
  - Contains: `route_id`, `distance_m`, `eta_unix_ms`, `next_turn_text`, `next_turn_bearing_deg`, `remaining_distance_m`, `estimated_duration_s`, `bounding_box`

**For navigation (Step 3+):**
- `PositionUpdate` - GPS location updates
  - Fields: `lat`, `lon`, `speed_m_s`, `bearing_deg`, `timestamp_ms`, `accuracy_m`, `altitude_m`
- `Control` with `START_NAV`/`STOP_NAV`/`PAUSE_NAV`/`RESUME_NAV` - Navigation control
  - Available ControlTypes: `REQUEST_ROUTE`, `START_NAV`, `STOP_NAV`, `ACK`, `NACK`, `REQUEST_BLOB`, `HEARTBEAT`, `PAUSE_NAV`, `RESUME_NAV`

**Message Wrapper:**
All messages are wrapped in a `Message` wrapper with a `oneof payload` field that can contain any of the above message types.

**Frame Structure** (for BLE transmission):
Each message is chunked into `Frame` messages for BLE:
- `magic` - 0x4E415645 ("NAVE")
- `msg_type` - Message type identifier
- `protocol_version` - Currently 1
- `route_id` - 16-byte UUID
- `seq_no` - Sequence number (0-based)
- `total_seqs` - Total number of frames
- `payload_len` - Length of payload in this frame
- `payload` - Actual data chunk
- `crc32` - CRC32 checksum

**nav-e API Usage** (Dart/Flutter):
```dart
import 'package:nav_e/bridge/lib.dart' as api;
import 'package:nav_e/core/device_comm/device_communication_service.dart';

// Send a route
await service.sendRoute(
  device: bluetoothDevice,
  routeJson: jsonEncode(routeData),
  onProgress: (progress) => print('Progress: ${progress * 100}%'),
);

// Send control command
await service.sendControlCommand(
  device: bluetoothDevice,
  routeId: routeId,
  controlType: ControlType.START_NAV,
  statusCode: 200,
  message: 'Starting navigation',
);
```

**nav-c-prototype Implementation** (Kotlin - to be implemented):
```kotlin
// Parse incoming frame
val frame = Frame.parseFrom(frameBytes)

// Validate CRC32
val expectedCrc = calculateCrc32(frame.payload)
if (expectedCrc != frame.crc32) {
    // Handle corrupted frame
}

// Reassemble frames into complete message
frameAssembler.addFrame(frame)
if (frameAssembler.isComplete()) {
    val messageBytes = frameAssembler.assemble()
    val message = Message.parseFrom(messageBytes)
    
    // Handle specific message type
    when (message.payloadCase) {
        Message.PayloadCase.ROUTE_BLOB -> handleRouteBlob(message.routeBlob)
        Message.PayloadCase.CONTROL -> handleControl(message.control)
        Message.PayloadCase.POSITION_UPDATE -> handlePositionUpdate(message.positionUpdate)
        // ... other cases
    }
}
```

#### 2.2 BLE Characteristics Setup
- **TX Characteristic** (nav-e → nav-c): For sending route data
- **RX Characteristic** (nav-c → nav-e): For acknowledgments and status
- **MTU Negotiation**: Request maximum MTU (typically 247-517 bytes)

## Implementation Steps

### Step 1: Basic Connectivity Test (Fake Data) — *done*

**Objective:** Confirm bidirectional communication works

**nav-e implementation:**
- Use existing `DeviceCommunicationService` — *done*
- Send test heartbeat using `sendControlCommand` — *done* (Device Comm Debug: "Send Heartbeat" button)
- Subscribe to RX characteristic to receive ACK — *done* (`subscribeToDevice`, `lastValueStream` → `Message.fromBuffer` → `messageStream`)
- Monitor connection state via `DeviceCommBloc` — *done*

**nav-c-prototype implementation:**
- BLE GATT server in `BluetoothService.kt` — *done*
- Parse incoming data: try raw `Message` first (single-packet Control/HEARTBEAT), then `Frame` reassembly — *done*
- On HEARTBEAT: update `lastHeartbeatTimestamp`, call `sendAck(routeId)` — *done*
- `sendAck`: build Control ACK, send via `notifyCharacteristicChanged` on RX — *done*
- OnboardingFragment2: show "Heartbeat received at HH:mm:ss" when connected — *done*

**Success criteria:**
- nav-e shows "Connected" to device; Send Heartbeat sends HEARTBEAT; nav-e can receive ACK (MessageFromDevice in log)
- nav-c displays heartbeat received timestamp — *done*
- Bidirectional communication confirmed

### Step 2: Send Real Route from Plan Route Screen

**Objective:** Transmit actual route data from nav-e to nav-c

**nav-e implementation:**
- Add "Send to (connected) Device" button in PlanRouteScreen
- Use `DeviceCommBloc.add(SendRouteToDevice(...))`
- Send `RouteBlob` with waypoints, polyline, distance, duration
- Monitor `DeviceCommSending` state for progress

**nav-c-prototype implementation:**
- Deserialize `RouteBlob` message
- Store waypoints in memory/database
- Parse polyline using Google Polyline decoder
- Display confirmation: "Route received: X km, Y waypoints"

**Success criteria:**
- Route data transmitted successfully
- nav-c displays route summary (distance, waypoints count)
- Confirmation message shown in nav-e

### Step 3: Map Display on nav-c-prototype

**Objective:** Visualize the received route on a map

**Requirements:**
- Integrate a mapping library (e.g., Mapbox, Google Maps, or OSM)
- Display route polyline on map
- Show current location marker
- Render waypoints

**Data flow:**
1. Receive `RouteBlob` with `encoded_polyline` or `raw_points`
2. Decode polyline into LatLng list
3. Draw route on map using map SDK
4. Listen for `PositionUpdate` messages from nav-e
5. Update current location marker in real-time

**Success criteria:**
- Route displayed correctly on map
- Current location marker updates smoothly
- Waypoints visible along route

### Step 4: Turn-by-Turn Navigation

**Objective:** Provide real-time navigation instructions

**nav-e sends:**
- `RouteLeg` with `steps` containing turn instructions
- `PositionUpdate` every 1-5 seconds during navigation
- Updated instructions as user progresses

**nav-c-prototype displays:**
- Current instruction text (e.g., "Turn left in 200m")
- Distance to next turn (`distance_m` from `Step`)
- Maneuver icon (`maneuver_type`)
- Progress bar or ETA to destination
- Map view centered on current position

**Success criteria:**
- Instructions update automatically as position changes
- Maneuver icons display correctly
- Distance countdown works accurately

## Additional Considerations

### Error Handling & Recovery
- **Connection loss**: Show reconnection UI on both sides with auto-retry
- **Frame corruption**: Use existing CRC32 validation in `Frame`
- **Timeout handling**: Retry failed transmissions (already in `DeviceCommunicationService`)
- **Partial data**: Handle incomplete route transmission gracefully

### Battery Optimization
- Send `BatteryStatus` from nav-c every 30-60s
- Adjust update frequency based on battery level
- Allow nav-e to pause updates if battery is low
- Use lower GPS accuracy when battery is critical

### Demo-Specific Enhancements
- **Onboarding progress indicator**: Show checkmarks for each step completed
- **Route preview**: Show route on nav-c before starting navigation
- **Voice cues**: Optional audio instructions (if nav-c has speakers)
- **Offline maps**: Pre-cache map tiles on nav-c for demo area
- **Connection persistence**: Save connection state across app restarts

## Implementation Checklist

### nav-e Tasks:
- [ ] Add demo device configuration (fixed UUID/name)
- [ ] Auto-connect to demo device on app start
- [x] Test heartbeat transmission using `createControlMessage` (Step 1: Device Comm Debug "Send Heartbeat")
- [ ] Add "Send to Demo Device" button in PlanRouteScreen
- [ ] Use existing `DeviceCommBloc` for route transmission
- [ ] Send `START_NAV` control message
- [ ] Stream `PositionUpdate` during navigation
- [ ] Handle connection state changes in UI

### nav-c-prototype Tasks:
- [x] Add protobuf dependencies (Kotlin protobuf or Java protobuf-lite)
- [x] Generate Kotlin code from `navigation.proto`
- [x] Create `BluetoothService.kt` with GATT server
- [x] Register nav-e service UUID and characteristics
- [x] Parse incoming `Frame` messages and reassemble; also parse raw `Message` (single-packet Control/HEARTBEAT)
- [x] Send ACK on HEARTBEAT via RX characteristic notify
- [x] Update onboarding screens with connection status (heartbeat timestamp in OnboardingFragment2)
- [x] Handle Bluetooth state changes (extend existing receiver)
- [ ] Deserialize `RouteBlob` protobuf (Step 2)
- [ ] Add map view with route display
- [ ] Implement turn-by-turn UI
- [ ] Add error handling for connection loss
- [ ] Create foreground service for persistent BLE connection

### Testing Strategy:
1. **Unit tests**: Protobuf serialization/deserialization on both sides
2. **Integration tests**: End-to-end route transmission with real data
3. **Connection tests**: Simulate connection loss and recovery
4. **Field tests**: Test with physical devices in real navigation scenarios
5. **Performance tests**: Measure battery drain and data transmission speed

## Technical Notes

### Protobuf Setup for Android
nav-c-prototype needs to add protobuf compilation to `build.gradle.kts`:
```kotlinDemo
}