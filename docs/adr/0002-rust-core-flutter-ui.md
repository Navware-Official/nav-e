# ADR-0002: Use Rust for Core Navigation Engine with Flutter for UI

## Status

**Accepted**

Date: 2025-12-16

## Context

Building a cross-platform navigation application requires balancing several competing concerns:

- **Performance**: Route calculation, real-time position tracking, and navigation logic need to be fast and efficient
- **Memory Safety**: Navigation apps run for extended periods; memory leaks and crashes are unacceptable
- **Cross-Platform**: Need to support Android, iOS, and potentially Wear OS from a single codebase
- **UI/UX**: Require rich, native-feeling user interfaces with smooth animations
- **Battery Life**: Critical for mobile navigation apps that run continuously
- **Developer Productivity**: Need rapid iteration on UI features
- **Type Safety**: Prevent runtime errors in critical navigation logic

Traditional approaches like pure native development (Swift/Kotlin) or pure cross-platform frameworks (React Native, Flutter alone) don't adequately address all these concerns.

## Decision

We adopt a **hybrid architecture** combining:

### Rust for Core Navigation Engine

The Rust `nav_engine` crate handles all navigation business logic:

- Route calculation and optimization
- Turn-by-turn navigation state management
- Position tracking and waypoint detection
- Device communication protocol implementation
- Traffic event processing
- Data persistence

### Flutter for UI Layer

Flutter handles all presentation concerns:

- User interface components and screens
- User interactions and gestures
- Map rendering and visualization
- State management (BLoC pattern)
- Platform-specific integrations
- Animations and transitions

### Flutter Rust Bridge for FFI

We use `flutter_rust_bridge` to connect the two layers with:

- Automatic FFI bindings generation
- Type-safe Rust ↔ Dart communication
- Async/await support across the boundary
- Minimal boilerplate code

### Two-Crate Architecture

- **`nav_engine`**: Internal Rust crate with core business logic
- **`nav_e_ffi`**: Thin FFI wrapper exposing public API to Flutter

This separation keeps the business logic pure while providing a clean FFI boundary.

## Consequences

### Positive

- **Performance**: Rust's zero-cost abstractions and lack of garbage collection provide excellent performance for navigation algorithms
- **Memory Safety**: Rust's ownership system prevents memory leaks, null pointer dereferencing, and data races
- **Battery Efficiency**: Compiled Rust code is more power-efficient than interpreted or JIT-compiled alternatives
- **Cross-Platform**: Flutter provides pixel-perfect consistency across Android and iOS with a single codebase
- **Type Safety**: Both Rust and Dart are strongly typed, catching errors at compile time
- **Concurrent Processing**: Rust's fearless concurrency enables safe parallel processing of navigation tasks
- **Small Binary Size**: Rust compiles to native code without runtime overhead
- **Developer Experience**: Flutter's hot reload enables rapid UI iteration, while Rust's compiler provides excellent error messages
- **Future-Proof**: Can share `nav_engine` with other platforms (web via WASM, desktop, embedded devices)

### Negative

- **Learning Curve**: Team needs expertise in both Rust and Flutter/Dart
- **Build Complexity**: Requires coordinating Rust and Flutter build systems
- **FFI Overhead**: Some performance cost when crossing the FFI boundary, though `flutter_rust_bridge` minimizes this
- **Debugging Complexity**: Debugging across FFI boundaries is more challenging than single-language apps
- **Dependency Management**: Must manage dependencies in both Cargo (Rust) and pub (Dart)
- **Tooling Integration**: IDE support for cross-language debugging is limited
- **Recruitment**: Finding developers skilled in both Rust and Flutter is harder than finding single-platform developers

### Neutral

- **Code Duplication**: Some data structures need to be defined in both Rust and Dart (though `flutter_rust_bridge` automates most of this)
- **Build Times**: Initial Rust compilation is slow, but incremental builds are fast
- **Platform-Specific Code**: Still need some platform-specific code for deep Android/iOS integrations

## Alternatives Considered

### Alternative 1: Pure Flutter (with Dart for Navigation Logic)

**Description:** Implement entire app including navigation engine in Flutter/Dart

**Pros:**
- Single language for entire stack
- Simpler build process
- Easier debugging
- Larger Flutter developer pool
- Faster initial development

**Cons:**
- Dart VM overhead impacts battery life during long navigation sessions
- Garbage collection pauses could affect real-time navigation
- Less efficient for CPU-intensive route calculations
- No compile-time guarantees about memory safety
- Difficult to reuse navigation logic on non-Flutter platforms

**Why rejected:** Performance and battery life are critical for navigation apps; Dart's VM overhead is unacceptable for long-running navigation sessions

### Alternative 2: Native Android/iOS with Shared C++ Core

**Description:** Write navigation engine in C++ with Kotlin (Android) and Swift (iOS) UIs

**Pros:**
- Excellent performance from C++
- Native platform UIs
- Well-established FFI patterns (JNI, Swift C interop)
- No runtime overhead

**Cons:**
- Must maintain separate UIs for Android and iOS (2-3x UI development effort)
- C++ lacks memory safety guarantees (null pointers, buffer overflows, use-after-free)
- Inconsistent UI/UX across platforms
- Complex manual FFI bindings
- C++ build systems are notoriously complex
- Difficult to find developers skilled in C++, Kotlin, AND Swift

**Why rejected:** Maintaining two separate native UIs would slow development significantly; C++ lacks Rust's memory safety guarantees

### Alternative 3: React Native with Native Modules

**Description:** Use React Native for UI with native Kotlin/Swift modules for performance-critical navigation

**Pros:**
- Large developer community
- Mature ecosystem
- JavaScript familiarity
- Hot reload

**Cons:**
- React Native's bridge has significant performance overhead
- Frequent breaking changes in React Native versions
- Inconsistent behavior across platforms
- Navigation logic would still be in unsafe languages (C++/Objective-C)
- JavaScript runtime overhead impacts battery
- Difficult to achieve native-feeling UIs

**Why rejected:** React Native's performance issues and maintenance burden are well-documented; doesn't address memory safety in core logic

### Alternative 4: Kotlin Multiplatform Mobile (KMM)

**Description:** Use Kotlin Multiplatform for shared business logic with native UIs

**Pros:**
- Kotlin is modern and safe
- Good Android integration
- Can share logic between Android and iOS
- Strong type system

**Cons:**
- Still requires separate UIs for Android and iOS
- iOS support is still evolving
- Not as performant as Rust or C++
- JVM overhead on Android
- Limited to mobile platforms (no web/desktop sharing)
- Smaller ecosystem than Flutter

**Why rejected:** Still requires maintaining two UIs; not as mature as Flutter for cross-platform; performance not as good as Rust

## Implementation

- **Implemented in:** feature/navigation-routing branch and earlier
- **Affected components:**
  - `native/nav_engine/` - Core Rust navigation engine
  - `native/nav_e_ffi/` - FFI wrapper crate
  - `lib/bridge/` - Generated Flutter bindings
  - `flutter_rust_bridge.yaml` - Bridge configuration
- **Migration path:** Initial implementation; all core business logic goes in Rust, all UI in Flutter

## References

- [Flutter Rust Bridge Documentation](https://cjycode.com/flutter_rust_bridge/)
- [Why Rust for Cross-Platform Development](https://blog.rust-lang.org/2021/02/08/Rust-1.50.0.html)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [docs/guides/flutter-rust-bridge.md](../guides/flutter-rust-bridge.md) - Implementation guide
- [Rust FFI Patterns](https://doc.rust-lang.org/nomicon/ffi.html)

---

## Notes

This hybrid architecture provides the best of both worlds: Rust's performance and safety for critical business logic, and Flutter's productivity and cross-platform UI capabilities. The two-crate architecture (nav_engine + nav_e_ffi) ensures clean separation between pure business logic and FFI concerns.
