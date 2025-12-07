# Device Communication Protocol

This directory contains the Protocol Buffers specification and implementation for device communication between the phone (navigation engine) and wearable devices (watch, custom hardware).

## Overview

The protocol is transport-agnostic and supports:
- Wear OS watches via MessageClient/ChannelClient
- Custom BLE devices via GATT characteristics
- Future transports (USB, WiFi Direct, etc.)

## Architecture

```
proto/
  └── navigation.proto          # Protocol definitions

native/nav_engine/
  ├── src/device_comm.rs       # Rust implementation
  └── build.rs                 # Protobuf code generation

lib/core/device_comm/
  └── proto/                   # Generated Dart files (after running script)
```

## Message Types

1. **RouteSummary** - Small, frequent UI updates (< 1KB)
   - Next turn instructions
   - Remaining distance/time
   - ETA

2. **RouteBlob** - Full route data (target < 50KB)
   - Complete waypoints
   - Turn-by-turn instructions
   - Encoded polyline
   - Optional compression

3. **PolylineSegment** - Chunked polyline streaming
   - For very large routes
   - Supports incremental rendering

4. **Control** - Commands and acknowledgments
   - START_NAV, STOP_NAV, PAUSE_NAV
   - ACK/NACK for reliability
   - HEARTBEAT for connection monitoring

5. **PositionUpdate** - Live location from device
   - Lat/lon coordinates
   - Speed and bearing
   - Accuracy metrics

6. **ErrorReport** - Error reporting
   - Error codes and messages
   - Context for debugging

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

### Rust (Phone Side)

```rust
use nav_engine::device_comm::*;
use uuid::Uuid;

// Create a route summary
let route_id = Uuid::new_v4();
let summary = create_route_summary(
    route_id,
    5000,  // 5km total
    1234567890000,  // ETA timestamp
    "Turn left onto Main St".to_string(),
    270,  // bearing in degrees
    1000,  // 1km remaining
    180,  // 3 minutes
    (52.0, 4.0, 52.5, 4.5),  // bounding box
);

// Serialize to bytes
let bytes = serialize_message(&Message {
    payload: Some(message::Payload::RouteSummary(summary)),
})?;

// Send over BLE (chunked automatically)
let frames = chunk_message(&msg, &route_id, 1, 247)?;
for frame in frames {
    // Send frame.payload over BLE characteristic
}
```

### Dart (Watch Side)

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

// Send acknowledgment
final ack = Control()
  ..header = (Header()
    ..protocolVersion = 1
    ..messageVersion = 1)
  ..type = ControlType.ACK
  ..routeId = routeId
  ..statusCode = 200
  ..messageText = 'Received';

final ackBytes = ack.writeToBuffer();
// Send over BLE...
```

## BLE Frame Format

For custom BLE devices, messages are chunked into frames:

```
Frame Structure (35-40 bytes overhead):
┌─────────────────────┬───────┐
│ magic (2B)          │ 0xNAVE│
│ msg_type (1B)       │ 1-6   │
│ protocol_version (1B│ 1     │
│ route_id (16B)      │ UUID  │
│ seq_no (4B)         │ 0..N  │
│ total_seqs (4B)     │ N+1   │
│ payload_len (2B)    │ bytes │
│ flags (1B)          │ 0x00  │
│ payload (var)       │ data  │
│ crc32 (4B)          │ check │
└─────────────────────┴───────┘
```

MTU assumptions:
- Minimum: 247 bytes (BLE 4.2)
- Optimal: 517 bytes (BLE 5.0+)
- Chunk size = MTU - 40

## Security

### Development (Wear OS)
- Relies on Wear OS platform security
- Encrypted channel managed by OS

### Production (Custom BLE)
- BLE pairing with LE Secure Connections
- HMAC-SHA256 signatures on RouteBlob
- Key exchange during initial pairing

## Performance Targets

- **RouteSummary**: < 500 bytes, sent every 1-5 seconds
- **RouteBlob**: < 50KB total, sent once per route
- **Polyline**: 200-1000 points after simplification
- **BLE throughput**: ~10-20 KB/s (depending on MTU)
- **ACK timeout**: 3 seconds
- **Retry limit**: 3 attempts

## Testing

```bash
# Test Rust implementation
cd native/nav_engine
cargo test device_comm

# Test frame assembly
cargo test test_frame_chunking_and_assembly
```

## Versioning

- **protocol_version**: Incremented for breaking changes
- **message_version**: Incremented for message-specific changes
- Fields are never removed, only deprecated
- New fields use new field numbers

## Troubleshooting

### "protoc: command not found"
Install Protocol Buffers compiler (see Prerequisites)

### "Failed to compile proto files"
Ensure proto file syntax is valid:
```bash
protoc --decode_raw < proto/navigation.proto
```

### BLE connection issues
- Check MTU negotiation
- Verify CRC32 checksums
- Monitor ACK/NACK messages
- Check sequence numbers for gaps

## Future Enhancements

- [ ] Compression support (zlib/gzip)
- [ ] Differential updates for route changes
- [ ] Battery-aware update frequency
- [ ] Multi-device synchronization
- [ ] Offline route caching
