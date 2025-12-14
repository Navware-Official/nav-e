# Protocol Buffers (Protobuf)

Protocol Buffers specification for device communication between the phone and wearable devices.

> **Related Documentation:**
> - [Device Comm Crate](device-comm.md) - Low-level protocol implementation
> - [Device Communication Guide](../guides/device-communication.md) - Flutter integration

## Overview

Located in `proto/navigation.proto`, this defines all message types for device communication. The protocol is transport-agnostic and designed for:
- Wear OS watches
- Custom BLE devices
- Future transports (USB, WiFi Direct, etc.)

## Message Types

| Message | Size | Purpose | Frequency |
|---------|------|---------|-----------|
| `RouteSummary` | < 1KB | Quick UI updates | Every 1-5s |
| `RouteBlob` | < 50KB | Complete route data | Once per route |
| `Control` | ~100B | Commands (ACK/NACK/START_NAV) | On-demand |
| `PositionUpdate` | ~100B | GPS location | Every 1-5s |
| `TrafficAlert` | ~500B | Traffic information | On event |
| `WaypointUpdate` | ~1KB | Waypoint arrivals | On event |
| `DeviceCapabilities` | ~500B | Device info | On connect |
| `BatteryStatus` | ~100B | Battery level | Every 30-60s |

For detailed message field descriptions, see `proto/navigation.proto`.

## Generating Code

### Prerequisites

Install protoc (Protocol Buffers compiler):
```bash
# Ubuntu/Debian
sudo apt install protobuf-compiler

# macOS
brew install protobuf

# Or download from: https://github.com/protocolbuffers/protobuf/releases
```

### Generate Dart Code

```bash
./scripts/generate_proto.sh
```

This creates:
- `lib/core/device_comm/proto/navigation.pb.dart`
- `lib/core/device_comm/proto/navigation.pbenum.dart`
- `lib/core/device_comm/proto/navigation.pbjson.dart`
- `lib/core/device_comm/proto/navigation.pbserver.dart`

### Generate Rust Code

Rust code is generated automatically during `cargo build` via `build.rs`.

## Usage Examples

### Dart Usage

```dart
import 'package:nav_e/core/device_comm/proto/navigation.pb.dart';

// Deserialize received bytes
final message = Message.fromBuffer(bytes);

if (message.hasRouteSummary()) {
  final summary = message.routeSummary;
  print('Next turn: ${summary.nextTurnText}');
  print('Distance: ${summary.remainingDistanceM}m');
  print('ETA: ${DateTime.fromMillisecondsSinceEpoch(summary.etaUnixMs)}');
}

// Create and send acknowledgment
final ack = Control()
  ..header = (Header()..protocolVersion = 1..messageVersion = 1)
  ..type = ControlType.ACK
  ..routeId = routeId
  ..statusCode = 200
  ..messageText = 'Received';

final ackBytes = ack.writeToBuffer();
```

For Rust examples, see [Device Comm documentation](device-comm.md#usage-examples).

## Protocol Design

### Versioning Strategy
- **protocol_version**: Breaking changes (incompatible wire format)
- **message_version**: Message-specific updates (new fields)
- Fields are never removed, only deprecated
- New fields always use new field numbers

### Security Considerations
- **Development**: Wear OS managed encryption
- **Production**: BLE pairing + HMAC-SHA256 signatures
- Optional message signing for RouteBlob integrity

### Performance Optimization
- Target: < 500 bytes for frequent updates (RouteSummary, PositionUpdate)
- Polyline simplification: 200-1000 points after Douglas-Peucker
- Optional compression for RouteBlob (future enhancement)

## Troubleshooting

**"protoc: command not found"**
- Install Protocol Buffers compiler (see Prerequisites above)

**"Failed to compile proto files"**
- Validate syntax: `protoc --decode_raw < proto/navigation.proto`
- Check protoc version: `protoc --version` (should be 3.x or higher)

**Generated files not found**
- Run `./scripts/generate_proto.sh` for Dart
- Rust files generate automatically via `build.rs` during cargo build

## See Also

- [Device Comm Crate](device-comm.md) - Frame chunking, CRC validation, BLE protocol
- [Device Communication Guide](../guides/device-communication.md) - Flutter integration examples
