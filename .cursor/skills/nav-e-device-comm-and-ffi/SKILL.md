---
name: nav-e-device-comm-and-ffi
description: Implements or extends device communication (BLE/Wear, protobuf, send flows) and Flutter–Rust FFI APIs in nav-e. Use when adding device message types, new send-to-device flows, transport changes, or when adding/changing Rust APIs exposed to Dart.
---

# nav-e: Device communication & FFI workflows

## When to use this skill
- Adding or changing **device communication**: new message types, new “send to device” flows (e.g. route, map region, map style, control), or transport (BLE vs Wear OS).
- Adding or changing **Rust APIs** used from Flutter: new or modified functions in the bridge.

---

## 1. Device communication

### Layers (top → bottom)
- **UI** → **DeviceCommBloc** (events/states) → **DeviceCommunicationService** → **FFI** (`prepare*`, `chunkMessageForBle`) → **Rust** (device_comm, protobuf) → **Transport** (BLE or Wear MethodChannel/EventChannel).

### Adding a new “send to device” flow
1. **Proto**: Add or reuse message in `proto/navigation.proto`. Regenerate Rust (and Dart if applicable); keep nav-c in sync.
2. **Rust**: In `native/nav_engine` (or device_comm) add prepare/serialize; expose in `native/nav_e_ffi` as a function returning bytes. Use `chunkMessageForBle` for framing.
3. **Dart**: In `DeviceCommunicationService` add a method that calls the new FFI API, builds frames, then `_sendFramesWithRetry` (or transport-specific send). Optionally add progress callback.
4. **BLoC**: Add event (e.g. `SendXToDevice`) and state handling in `DeviceCommBloc`; call the new service method.
5. **Docs**: Update `docs/guides/device-communication.md` (and `docs/rust/device-comm.md` / `docs/rust/protobuf.md` if needed).

### Transport
- **Wear OS (prototype)**: `WearDeviceCommTransport`; MethodChannel `org.navware.nav_e/wear` (`getConnectedNodes`, `sendFrames`); EventChannel for incoming. Paths: `/nav/frame` (phone→watch), `/nav/msg` (watch→phone).
- **BLE**: `BleDeviceCommTransport`; inject in `main.dart` (e.g. Android: choose Wear vs BLE). Same frame format and protobuf.

---

## 2. Flutter–Rust FFI (adding/changing API)

### Steps
1. **Internal API**: Implement or change logic in `native/nav_engine/src/api/` (e.g. `device_comm.rs`, `routes.rs`).
2. **FFI surface**: Add or update a thin `#[frb]` wrapper in `native/nav_e_ffi/src/lib.rs` that delegates to `nav_engine::api::*`. Use types supported by flutter_rust_bridge (e.g. `String`, `Vec<u8>`, primitives, simple structs).
3. **Codegen**: Run `make codegen` to regenerate Dart in `lib/bridge/`.
4. **Dart**: Use only `import 'package:nav_e/bridge/lib.dart' as api;` and call the new/changed function. Do not import from generated subdirs (application/, infrastructure/).
5. **Verify**: `make test-rust` (or `make test`). For Android: `make build-android` if you changed native code.

### Conventions
- No business logic in `nav_e_ffi` — only pass-through. Keep `nav_engine` as the single place for domain and application logic.

---

## References
- Device comm guide: `docs/guides/device-communication.md`
- Rust device comm & protobuf: `docs/rust/device-comm.md`, `docs/rust/protobuf.md`
- Flutter–Rust bridge: `docs/guides/flutter-rust-bridge.md`
- Rust layout: `docs/rust/overview.md`
