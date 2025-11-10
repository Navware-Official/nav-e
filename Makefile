SHELL := /bin/bash

.PHONY: help codegen build-native build-android build-android-all clean-native fmt test ci

HELPER := \
  echo "Usage:\n  make codegen           # Run flutter_rust_bridge_codegen and generate Dart bindings into lib/bridge\n  make build-native      # Build native Rust crate (desktop)\n  make build-android     # Build Android native libs for arm64 and copy to android/app/src/main/jniLibs\n  make build-android-all # Build Android native libs for common ABIs and copy to jniLibs\n  make clean-native      # cargo clean in native/nav_engine\n  make fmt               # cargo fmt in native/nav_engine (rustfmt required)\n  make test              # run flutter test\n  make ci                # run codegen + build-native (for CI)"

help:
	@$(HELPER)

## Generate Dart bindings with flutter_rust_bridge_codegen
codegen:
	@command -v flutter_rust_bridge_codegen >/dev/null 2>&1 || { echo "flutter_rust_bridge_codegen not found. Install with: cargo install flutter_rust_bridge_codegen"; exit 1; }
	@echo "Running FRB codegen -> lib/bridge"
	flutter_rust_bridge_codegen generate --rust-root native/nav_engine -r crate:: -d lib/bridge

## Build the native Rust crate for desktop (release)
build-native:
	@echo "Building native Rust crate (release)..."
	@cd native/nav_engine && cargo build --release

## Build Android libs via cargo-ndk (arm64 only). Requires cargo-ndk and NDK installed.
build-android:
	@command -v cargo-ndk >/dev/null 2>&1 || { echo "cargo-ndk not found. Install with: cargo install cargo-ndk"; exit 1; }
	@echo "Building Android native libs (arm64-v8a) and copying to android/app/src/main/jniLibs"
	@cd native/nav_engine && cargo ndk -t arm64-v8a -o ../../android/app/src/main/jniLibs build --release

## Build Android libs for multiple ABIs
build-android-all:
	@command -v cargo-ndk >/dev/null 2>&1 || { echo "cargo-ndk not found. Install with: cargo install cargo-ndk"; exit 1; }
	@echo "Building Android native libs (arm64-v8a, armeabi-v7a, x86_64) and copying to android/app/src/main/jniLibs"
	@cd native/nav_engine && cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 -o ../../android/app/src/main/jniLibs build --release

clean-native:
	@cd native/nav_engine && cargo clean

fmt:
	@command -v rustfmt >/dev/null 2>&1 || { echo "rustfmt not found. Install with: rustup component add rustfmt"; exit 1; }
	@cd native/nav_engine && cargo fmt

test:
	@echo "Running Flutter tests..."
	flutter test

ci: codegen build-native
