# Native library (libnav_e_ffi.so)

This directory is populated by the build. **If you see "failed to load dynamic library 'libnav_e_ffi.so'" or "library not found"**, build the Android native libs from the project root.

**One-time setup:**

1. Install Android targets for Rust:
   ```bash
   rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
   ```
2. Install cargo-ndk: `cargo install cargo-ndk`
3. Ensure Android NDK is installed (e.g. via Android Studio SDK Manager, or `sdkmanager "ndk;..."`).

**Build:**

```bash
make build-android      # arm64-v8a only (most physical devices)
# or
make build-android-all  # arm64-v8a, armeabi-v7a, x86_64 (emulator + devices)
```

After building, you should see e.g. `arm64-v8a/libnav_e_ffi.so`. Then run the Flutter app again (full run, not hot reload).
