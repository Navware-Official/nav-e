# Device Communication Crate (`device_comm`)

The `device_comm` crate handles low-level communication with BLE devices, including message serialization, chunking, and frame reassembly.

## Overview

This crate provides a robust protocol for sending navigation data to devices over Bluetooth Low Energy (BLE), which has strict MTU (Maximum Transmission Unit) limitations. It handles:

- **Protocol Buffers** - Efficient binary serialization
- **Frame Chunking** - Splitting large messages into BLE-compatible frames
- **CRC32 Validation** - Ensuring data integrity
- **Frame Reassembly** - Reconstructing complete messages from frames
- **Error Recovery** - Detecting missing/corrupted frames

## Architecture

```
Navigation Data (JSON/Struct)
        ↓
   Protobuf Message
        ↓
   Serialize to bytes
        ↓
   Chunk into BLE frames (with CRC32)
        ↓
   Transmit via BLE
        ↓
   Reassemble on device
        ↓
   Validate & Deserialize
```

## Core Components

### 1. Protocol Definition

Located in `proto/navigation.proto`, defines all message types:

```proto
message RouteBlob {
  Header header = 1;
  bytes route_id = 2;
  repeated Waypoint waypoints = 3;
  repeated RouteLeg legs = 4;
  // ... more fields
}
```

**Message Types:**
- `RouteSummary` - Quick status updates (distance, ETA, next turn)
- `RouteBlob` - Complete route with waypoints and geometry
- `Control` - Commands and acknowledgments (ACK, NACK, START_NAV)
- `PositionUpdate` - GPS location updates
- `TrafficAlert` - Real-time traffic information
- `WaypointUpdate` - Waypoint arrival notifications
- `DeviceCapabilities` - Device info and capabilities
- `BatteryStatus` - Battery level updates

### 2. Frame Structure

Each BLE frame contains:

```rust
pub struct Frame {
    magic: u32,              // 0x4E415645 ("NAVE")
    msg_type: u32,           // Message type identifier
    protocol_version: u32,   // Protocol version (currently 1)
    route_id: Vec<u8>,       // 16-byte UUID
    seq_no: u32,             // Sequence number (0-based)
    total_seqs: u32,         // Total number of frames
    payload_len: u32,        // Length of payload in this frame
    flags: u32,              // Reserved for future use
    payload: Vec<u8>,        // Actual data chunk
    crc32: u32,              // CRC32 checksum of payload
}
```

**Frame Overhead:** ~40 bytes per frame

### 3. Chunking Algorithm

The `chunk_message()` function splits messages into BLE-compatible frames:

```rust
pub fn chunk_message(
    msg: &proto::Message,
    route_id: &Uuid,
    msg_type: u32,
    mtu: usize,
) -> Result<Vec<Frame>>
```

**Parameters:**
- `msg` - The protobuf message to chunk
- `route_id` - Unique route identifier (UUID)
- `msg_type` - Message type code
- `mtu` - BLE Maximum Transmission Unit (typically 247 bytes)

**Algorithm:**
1. Serialize message to bytes
2. Calculate chunk size: `mtu - FRAME_OVERHEAD` (max 512 bytes)
3. Split payload into chunks
4. For each chunk:
   - Calculate CRC32 checksum
   - Create frame with sequence number
   - Add metadata (total frames, route_id, etc.)

### 4. Frame Reassembly

The `FrameAssembler` collects frames and reconstructs the original message:

```rust
let mut assembler = FrameAssembler::new();

// Add frames as they arrive
assembler.add_frame(frame)?;

// Check if complete
if assembler.is_complete() {
    let payload = assembler.assemble()?;
    let message = deserialize_proto_message(&payload)?;
}

// Check for missing frames
let missing = assembler.missing_sequences();
if !missing.is_empty() {
    // Request retransmission
}
```

**Features:**
- **Magic Number Validation** - Rejects invalid frames
- **CRC Verification** - Detects corrupted frames
- **Sequence Tracking** - Identifies missing frames
- **Out-of-Order Support** - Frames can arrive in any order

## Usage Examples

### Example 1: Prepare and Send Route

```rust
use device_comm::{chunk_message, proto};
use uuid::Uuid;

// Create route message
let route_blob = proto::RouteBlob {
    header: Some(proto::Header {
        protocol_version: 1,
        message_version: 1,
    }),
    route_id: route_id.as_bytes().to_vec(),
    waypoints: vec![/* ... */],
    legs: vec![/* ... */],
    // ...
};

let message = proto::Message {
    payload: Some(proto::message::Payload::RouteBlob(route_blob)),
};

// Chunk for BLE transmission (MTU = 247)
let frames = chunk_message(&message, &route_id, 2, 247)?;

// Send each frame via BLE
for frame in frames {
    let frame_bytes = serialize_frame(&frame)?;
    bluetooth_write(frame_bytes).await?;
}
```

### Example 2: Receive and Reassemble

```rust
use device_comm::FrameAssembler;

let mut assembler = FrameAssembler::new();

// As frames arrive from BLE
loop {
    let frame_bytes = bluetooth_read().await?;
    let frame = deserialize_frame(&frame_bytes)?;
    
    // Add frame to assembler
    if let Err(e) = assembler.add_frame(frame) {
        eprintln!("Frame error: {}", e);
        continue;
    }
    
    // Check if complete
    if assembler.is_complete() {
        let payload = assembler.assemble()?;
        let message = deserialize_proto_message(&payload)?;
        
        // Process complete message
        handle_message(message)?;
        
        // Reset for next message
        assembler.reset();
        break;
    }
}
```

### Example 3: Send Control Command

```rust
use device_comm::proto::{Control, ControlType};

let ack = Control {
    header: Some(proto::Header {
        protocol_version: 1,
        message_version: 1,
    }),
    r#type: ControlType::Ack as i32,
    route_id: route_id.as_bytes().to_vec(),
    status_code: 200,
    message_text: "Route received".to_string(),
    seq_no: 0,
};

let message = proto::Message {
    payload: Some(proto::message::Payload::Control(ack)),
};

let frames = chunk_message(&message, &route_id, 3, 247)?;
// Send frames...
```

## Integration with nav_engine

The `nav_engine` API layer provides FFI-friendly wrappers:

```rust
// nav_engine/src/api/device_comm.rs

pub fn prepare_route_message(route_json: String) -> Result<Vec<u8>> {
    // Parse JSON → Convert to protobuf → Serialize to bytes
}

pub fn chunk_message_for_ble(
    message_bytes: Vec<u8>,
    route_id: String,
    mtu: u32,
) -> Result<Vec<Vec<u8>>> {
    // Deserialize → Chunk using device_comm → Return frame bytes
}

pub fn reassemble_frames(frame_bytes: Vec<Vec<u8>>) -> Result<Vec<u8>> {
    // Deserialize frames → Use FrameAssembler → Return message bytes
}
```

These functions are exposed via FFI for Flutter integration. See `native/nav_e_ffi/src/lib.rs` for bindings.

## Error Handling

```rust
use device_comm::{DeviceError, Result};

match assembler.add_frame(frame) {
    Ok(()) => { /* Frame added successfully */ },
    Err(DeviceError::CrcMismatch { expected, actual }) => {
        // Request retransmission of this frame
        request_retransmit(frame.seq_no);
    },
    Err(DeviceError::InvalidFrame(msg)) => {
        // Bad frame, skip it
        eprintln!("Invalid frame: {}", msg);
    },
    Err(e) => {
        // Other error
        eprintln!("Frame error: {}", e);
    }
}
```

## Protocol Constants

```rust
// Protocol version
const PROTOCOL_VERSION: u32 = 1;

// Frame magic number ("NAVE" in ASCII)
const FRAME_MAGIC: u32 = 0x4E415645;

// Default BLE MTU (Android/iOS standard)
const DEFAULT_MTU: usize = 247;

// Frame overhead (headers, metadata, CRC)
const FRAME_OVERHEAD: usize = 40;
```

## Performance Considerations

### Chunk Size Optimization

```rust
// Effective payload per frame
let chunk_size = (mtu - FRAME_OVERHEAD).min(512);

// For MTU = 247:
// chunk_size = (247 - 40).min(512) = 207 bytes per frame
```

### Message Size Examples

| Message Type | Size | Frames (MTU=247) |
|-------------|------|------------------|
| Control (ACK) | ~50 bytes | 1 frame |
| RouteSummary | ~120 bytes | 1 frame |
| Position Update | ~80 bytes | 1 frame |
| RouteBlob (10 waypoints) | ~2 KB | ~10 frames |
| RouteBlob (100 waypoints) | ~15 KB | ~73 frames |

### Transmission Time Estimates

Assuming BLE throughput of ~10 KB/s:

- Small message (1 frame): < 100ms
- Medium route (10 frames): ~1 second
- Large route (73 frames): ~7 seconds

## Testing

The crate includes comprehensive tests:

```bash
cd native/device_comm
cargo test
```

**Test Coverage:**
- CRC32 calculation accuracy
- Frame chunking and reassembly
- Out-of-order frame handling
- Error detection (CRC mismatch, invalid frames)
- Message type serialization/deserialization

## See Also

- [Device Communication Guide](../guides/device-communication.md) - Flutter integration
- [Protobuf Documentation](protobuf.md) - Message definitions
- [Architecture Overview](../architecture/overview.md) - System design
