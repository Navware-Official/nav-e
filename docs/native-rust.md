Nav Engine & FRB helper

This folder contains a minimal Rust crate (`nav_engine`) intended to be used via
flutter_rust_bridge. It currently exposes a single function `geocode_search`
that performs a Nominatim search and returns the raw JSON string.

Quick steps:

1. Generate Dart bindings (after installing `flutter_rust_bridge_codegen`):

   flutter_rust_bridge_codegen --rust-input native/nav_engine/src/lib.rs --dart-output lib/bridge/ffi.dart

2. Build Rust library for a platform (example: macOS / Linux):

   cd native/nav_engine
   cargo build --release

3. Replace the temporary shim `lib/bridge/ffi.dart` with the generated file.

4. Swap the DI to use `GeocodingRepositoryFrbImpl` in your `main.dart`.

Typed bindings note
-------------------
This crate exposes two helper functions:

- `geocode_search` — returns the raw JSON string response from Nominatim (good for quick fallback or when you prefer to reuse existing Dart JSON parsing).
- `geocode_search_typed` — returns a typed `Vec<FrbGeocodingResult>` which FRB will map to Dart classes when you run codegen. Prefer using typed bindings when you want safer, strongly-typed Dart bindings.

When you run `flutter_rust_bridge_codegen`, it will generate Dart classes for `FrbGeocodingResult` and typed functions for `geocode_search_typed`.
