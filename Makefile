SHELL := /bin/bash

.PHONY: help codegen build-native build-android build-android-all clean-native fmt test ci migrate-new migrate-status

help:
	@echo "Usage:"
	@echo "  make codegen           # Run flutter_rust_bridge_codegen (v2.x) and generate Dart bindings into lib/bridge"
	@echo "  make build-native      # Build native Rust crate (desktop)"
	@echo "  make build-android     # Build Android native libs for arm64 and copy to android/app/src/main/jniLibs"
	@echo "  make build-android-all # Build Android native libs for common ABIs and copy to jniLibs"
	@echo "  make clean-native      # cargo clean in native/nav_engine"
	@echo "  make fmt               # cargo fmt in native/nav_engine (rustfmt required)"
	@echo "  make test              # run flutter test"
	@echo "  make ci                # run codegen + build-native (for CI)"
	@echo "  make migrate-new       # Create a new database migration file with timestamp"
	@echo "  make migrate-status    # Show status of all migrations (applied/pending)"

## Generate Dart bindings with flutter_rust_bridge_codegen
codegen:
	@command -v flutter_rust_bridge_codegen >/dev/null 2>&1 || { echo "flutter_rust_bridge_codegen not found. Install with: cargo install flutter_rust_bridge_codegen --version 2.11.1 or 'dart pub global activate flutter_rust_bridge_codegen 2.11.1'"; exit 1; }
	@echo "Running FRB codegen -> lib/bridge"
	flutter_rust_bridge_codegen generate
	@echo "Running post-codegen cleanup..."
	@./scripts/post_codegen.sh

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

## Create a new migration file with timestamp
migrate-new:
	@./scripts/create_migration.sh

## Show migration status
migrate-status:
	@echo "Migration status:"
	@echo "Migrations are applied automatically when the app starts via Database::new()"
	@echo ""
	@echo "Defined migrations:"
	@ls -1 native/nav_engine/src/migrations/*.rs 2>/dev/null | grep -v "mod.rs" | sed 's/.*\///;s/\.rs//' | sed 's/^/  /' || echo "  No migrations found"
	@echo ""
	@echo "To create a new migration: make migrate-new"
