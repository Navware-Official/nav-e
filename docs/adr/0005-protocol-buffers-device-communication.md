# ADR-0005: Implement Protocol Buffers for Device Communication

## Status

**Accepted**

Date: 2025-12-16

## Context

The nav-e navigation app needs to communicate with external devices (Wear OS watches, custom BLE navigation devices) to:

- **Send route information** (summary, waypoints, turn-by-turn instructions)
- **Push position updates** during navigation
- **Deliver traffic alerts** affecting the current route
- **Receive device status** (battery, connection quality)
- **Handle control messages** (pause, resume, cancel navigation)

The device communication protocol must:

- **Be efficient**: Minimize data transfer over bandwidth-constrained connections (BLE typically 20-247 bytes per packet)
- **Be portable**: Work across different device types (Wear OS, custom BLE hardware, future platforms)
- **Be versioned**: Support protocol evolution without breaking compatibility
- **Be type-safe**: Prevent runtime errors from malformed messages
- **Support multiple transports**: Work over BLE, WiFi, WebSockets, etc.
- **Be language-agnostic**: Enable implementation in Rust, Kotlin, Dart, C++, etc.
- **Be fast**: Low serialization/deserialization overhead
- **Be compact**: Small binary size for embedded devices

We need to choose a serialization format and protocol design for reliable cross-device communication.

## Decision

We adopt **Protocol Buffers (protobuf)** as the serialization format for all device communication, with a custom transport layer for reliable message delivery over BLE.

### Protocol Design

**Message Types** (defined in `proto/navigation.proto`):
- `RouteSummary` - High-level route info (distance, duration, destination)
- `RouteBlob` - Full route data with waypoints and geometry
- `PositionUpdate` - Current GPS position and navigation state
- `TrafficAlert` - Real-time traffic events
- `ControlMessage` - Navigation commands (pause, resume, cancel)
- `DeviceStatus` - Battery level, connection quality

**Key Design Decisions**:
- **Transport-agnostic protocol**: Protobuf messages can be sent over any transport (BLE, TCP, UDP, WebSockets)
- **Versioning strategy**: Include `protocol_version` in messages for forward/backward compatibility
- **Size optimization**: Keep frequent messages (PositionUpdate) under 500 bytes
- **Enum-based message types**: Discriminated union pattern for message routing
- **Optional fields**: Use protobuf optional/required strategically to minimize payload

### Rust Implementation

- `prost` crate for Rust protobuf support
- `ProtobufDeviceCommunicator` adapter implementing `DeviceCommunicationPort`
- Automatic code generation from `.proto` files
- Integration with domain layer via adapter pattern

### Flutter Implementation

- `protobuf` package for Dart
- `DeviceCommunicationService` handling serialization and transport
- Generated Dart classes from `.proto` files
- BLoC integration for reactive state management

### BLE Transport Layer

Custom frame chunking protocol for BLE:
- Magic number validation (0xCAFE)
- CRC32 checksums for data integrity
- Sequence tracking for reassembly
- MTU-aware chunking (typically 247 bytes after headers)

## Consequences

### Positive

- **Compact Binary Format**: Much smaller than JSON (typically 3-10x smaller), critical for BLE's bandwidth constraints
- **Type Safety**: Compile-time checking in both Rust and Dart prevents runtime errors
- **Cross-Language Support**: Official libraries for Rust, Dart, Kotlin, Swift, C++, Python, etc.
- **Backward Compatibility**: Can add new fields without breaking old clients (forward/backward compatibility built-in)
- **Fast Serialization**: Binary format is much faster to serialize/deserialize than JSON parsing
- **Schema Definition**: `.proto` files serve as documentation and contract between systems
- **Code Generation**: Automatic generation of type-safe code in multiple languages
- **Industry Standard**: Proven at scale by Google, gRPC, and many others
- **Schema Evolution**: Can deprecate fields, add optional fields, rename fields safely
- **Memory Efficient**: No intermediate parsing step like JSON; direct binary access

### Negative

- **Not Human Readable**: Cannot inspect messages by eye like JSON (need protobuf tools)
- **Build Complexity**: Requires protobuf compiler and code generation in build pipeline
- **Debugging Difficulty**: Binary format is harder to debug than text-based protocols
- **Breaking Changes**: Removing required fields or changing field types breaks compatibility
- **Learning Curve**: Team needs to understand protobuf schema language and best practices
- **Tooling Required**: Need protobuf inspector tools for debugging (protoc, protoscope, etc.)
- **Size vs JSON**: While smaller, still larger than custom binary protocols

### Neutral

- **Field Numbers**: Must carefully manage field numbers for backward compatibility
- **Generated Code Size**: Generated code can be large for complex schemas
- **Reflection**: Limited runtime reflection compared to JSON
- **Compression**: Can add compression layer if needed (though protobuf is already compact)

## Alternatives Considered

### Alternative 1: JSON

**Description:** Use JSON for all device messages

**Pros:**
- Human-readable for debugging
- No code generation needed
- Native support in all languages
- Easy to test manually
- Flexible schema

**Cons:**
- **Much larger payloads**: 3-10x bigger than protobuf, problematic for BLE's 20-247 byte MTU
- Slower parsing (string processing)
- No compile-time type checking
- More battery consumption (parsing overhead)
- Bandwidth waste on constrained connections

**Why rejected:** JSON's size overhead is unacceptable for BLE communication; would require excessive chunking and reassembly

### Alternative 2: MessagePack

**Description:** Binary JSON-like format

**Pros:**
- Smaller than JSON
- Simpler than protobuf
- Self-describing format
- Good library support

**Cons:**
- Not as compact as protobuf
- No schema definition (no contract enforcement)
- No type safety or code generation
- Less efficient than protobuf for repeated serialization
- Smaller ecosystem than protobuf

**Why rejected:** Lack of schema and type safety; not significantly simpler than protobuf; less industry adoption

### Alternative 3: FlatBuffers

**Description:** Zero-copy binary serialization from Google

**Pros:**
- Even faster than protobuf (no deserialization needed)
- Zero-copy access to data
- Smaller memory footprint
- Good for embedded systems

**Cons:**
- More complex schema language
- Mutable buffers are tricky
- Less mature ecosystem than protobuf
- Harder to debug
- Overkill for our use case (we're not that performance-constrained)
- Fewer language bindings than protobuf

**Why rejected:** Added complexity not justified for our needs; protobuf's performance is sufficient for navigation data

### Alternative 4: Cap'n Proto

**Description:** Alternative to protobuf with zero-copy design

**Pros:**
- Faster than protobuf (zero-copy)
- No encoding/decoding step
- Compact binary format

**Cons:**
- Less mature than protobuf
- Smaller ecosystem and community
- Fewer language bindings
- More complex to use correctly
- Not widely adopted

**Why rejected:** Smaller ecosystem; protobuf's maturity and tooling are more valuable than marginal performance gains

### Alternative 5: Custom Binary Protocol

**Description:** Design our own binary message format

**Pros:**
- Complete control over format
- Potentially smallest possible size
- No dependencies
- Optimized for exact use case

**Cons:**
- **Massive development effort**: Must implement serialization, versioning, error handling from scratch
- No tooling (need to build inspectors, validators, etc.)
- Error-prone (easy to introduce bugs)
- Hard to maintain as protocol evolves
- No type safety across language boundaries
- Difficult to onboard new developers

**Why rejected:** Not core to our business; protobuf solves this problem excellently; building custom protocol would take weeks/months and be bug-prone

## Implementation

- **Implemented in:** feature/navigation-routing branch
- **Affected components:**
  - `proto/navigation.proto` - Protobuf schema definition
  - `native/nav_engine/src/infrastructure/protobuf_adapter.rs` - Rust serialization adapter
  - `lib/core/device_comm/device_communication_service.dart` - Flutter serialization service
  - `lib/bridge/generated/` - Generated protobuf code for Dart
  - Build scripts for protobuf code generation
- **Migration path:** Initial implementation; all device communication uses protobuf from the start

## References

- [Protocol Buffers Documentation](https://protobuf.dev/)
- [Protocol Buffers Language Guide](https://protobuf.dev/programming-guides/proto3/)
- [prost - Rust protobuf implementation](https://github.com/tokio-rs/prost)
- [protobuf Dart package](https://pub.dev/packages/protobuf)
- [docs/rust/protobuf.md](../rust/protobuf.md) - Detailed protobuf specification
- [docs/guides/device-communication.md](../guides/device-communication.md) - BLE protocol implementation

---

## Notes

### Protocol Evolution Strategy

When evolving the protocol:

1. **Never reuse field numbers**: Once a field is deprecated, its number is retired forever
2. **Add fields as optional**: New fields should be optional to maintain backward compatibility
3. **Use reserved keyword**: Mark deprecated field numbers as `reserved` in `.proto` file
4. **Version bumps**: Increment `protocol_version` for breaking changes
5. **Graceful degradation**: Older devices should continue working when new fields are added

### Message Size Guidelines

From protobuf.md documentation:

- **PositionUpdate**: < 100 bytes (sent frequently)
- **RouteSummary**: < 500 bytes
- **RouteBlob**: Can be larger, chunked by BLE transport
- **TrafficAlert**: < 300 bytes
- **ControlMessage**: < 50 bytes

### BLE-Specific Considerations

The custom BLE chunking protocol handles:
- **MTU limitations**: Typical BLE MTU is 247 bytes after headers
- **Fragmentation**: Large protobuf messages split into chunks
- **Reassembly**: Chunks reassembled using sequence numbers
- **Integrity**: CRC32 validates complete messages
- **Reliability**: Detect and handle corrupted or lost chunks

This transport layer is separate from protobuf, making it easy to use protobuf over other transports (WebSocket, TCP) in the future.

### Future Enhancements

Potential improvements:

1. **Compression**: Add zlib/zstd compression for large messages (RouteBlob)
2. **Selective Updates**: Send only changed fields using protobuf field masks
3. **Batching**: Batch multiple small messages to reduce BLE overhead
4. **Delta Encoding**: Send position deltas instead of full coordinates
