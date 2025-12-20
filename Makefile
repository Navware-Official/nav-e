SHELL := /bin/bash

.PHONY: help codegen build-native build-android build-android-all clean-native fmt fmt-rust fmt-flutter test ci migrate-new migrate-status full-rebuild android-dev rust-only

help:
	@echo "Workflow commands:"
	@echo "  make full-rebuild      # Codegen + build Android libs (after changing Rust signatures)"
	@echo "  make android-dev       # Full rebuild + hot restart Flutter app"
	@echo "  make rust-only         # Build Android libs only (after changing Rust implementation)"
	@echo ""
	@echo "Individual commands:"
	@echo "  make codegen           # Run flutter_rust_bridge_codegen (v2.x) and generate Dart bindings into lib/bridge"
	@echo "  make build-native      # Build native Rust crate (desktop)"
	@echo "  make build-android     # Build Android native libs for arm64 and copy to android/app/src/main/jniLibs"
	@echo "  make build-android-all # Build Android native libs for common ABIs and copy to jniLibs"
	@echo "  make clean-native      # cargo clean in native/nav_engine"
	@echo "  make fmt               # Format both Rust and Flutter/Dart code"
	@echo "  make fmt-rust          # Format Rust code only"
	@echo "  make fmt-flutter       # Format Flutter/Dart code only"
	@echo "  make lint              # Run linters on both Rust and Flutter code"
	@echo "  make lint-rust         # Run clippy on Rust code"
	@echo "  make lint-flutter      # Run dart analyze on Flutter code"
	@echo "  make test              # run flutter test"
	@echo "  make ci                # run codegen + build-native (for CI)"
	@echo "  make migrate-new       # Create a new database migration file with timestamp"
	@echo "  make migrate-status    # Show status of all migrations (applied/pending)"

## Generate Dart bindings with flutter_rust_bridge_codegen
codegen:
	@command -v flutter_rust_bridge_codegen >/dev/null 2>&1 || { echo "flutter_rust_bridge_codegen not found. Install with: cargo install flutter_rust_bridge_codegen --version 2.11.1 or 'dart pub global activate flutter_rust_bridge_codegen 2.11.1'"; exit 1; }
	@echo "Running FRB codegen -> lib/bridge"
	flutter_rust_bridge_codegen generate

## Build the native Rust crate for desktop (release)
build-native:
	@echo "Building native Rust crate (release)..."
	@cd native/nav_e_ffi && cargo build --release

## Build Android libs via cargo-ndk (arm64 only). Requires cargo-ndk and NDK installed.
build-android:
	@command -v cargo-ndk >/dev/null 2>&1 || { echo "cargo-ndk not found. Install with: cargo install cargo-ndk"; exit 1; }
	@echo "Building Android native libs (arm64-v8a) and copying to android/app/src/main/jniLibs"
	@cd native/nav_e_ffi && cargo ndk -t arm64-v8a -o ../../android/app/src/main/jniLibs build --release

## Build Android libs for multiple ABIs
build-android-all:
	@command -v cargo-ndk >/dev/null 2>&1 || { echo "cargo-ndk not found. Install with: cargo install cargo-ndk"; exit 1; }
	@echo "Building Android native libs (arm64-v8a, armeabi-v7a, x86_64) and copying to android/app/src/main/jniLibs"
	@cd native/nav_e_ffi && cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 -o ../../android/app/src/main/jniLibs build --release

clean-native:
	@cd native/nav_e_ffi && cargo clean
	@cd native/nav_engine && cargo clean

clean-android:
	make clean-native
	@make build-android
	@flutter run
	@echo "Android clean completed."

## Format Rust code
fmt-rust:
	@command -v rustfmt >/dev/null 2>&1 || { echo "rustfmt not found. Install with: rustup component add rustfmt"; exit 1; }
	@echo "Formatting Rust code..."
	@cd native/nav_e_ffi && cargo fmt
	@cd native/nav_engine && cargo fmt
	@echo "✓ Rust code formatted"

## Format Flutter/Dart code
fmt-flutter:
	@command -v dart >/dev/null 2>&1 || { echo "dart not found. Install Flutter SDK"; exit 1; }
	@echo "Formatting Flutter/Dart code..."
	@dart format .
	@echo "✓ Flutter/Dart code formatted"

## Format both Rust and Flutter code
fmt: fmt-rust fmt-flutter
	@echo "✓ All code formatted"

## Run linters on Rust code
lint-rust:
	@command -v cargo >/dev/null 2>&1 || { echo "cargo not found. Install Rust toolchain"; exit 1; }
	@echo "Running clippy on Rust code..."
	@cd native/nav_engine && cargo clippy -- -D warnings
	@cd native/nav_e_ffi && cargo clippy --allow-staged
	@echo "✓ Rust linting passed"

## Run linters on Flutter code
lint-flutter:
	@command -v dart >/dev/null 2>&1 || { echo "dart not found. Install Flutter SDK"; exit 1; }
	@echo "Running dart analyze..."
	@dart analyze
	@echo "✓ Flutter linting passed"

## Run all linters
lint: lint-rust lint-flutter
	@echo "✓ All linting checks passed"

test:
	@echo "Running Flutter tests..."
	flutter test
	@echo "Running Rust tests..."
	@cd native/nav_engine && cargo test
	@echo "✓ All tests ran"

ci: codegen build-native

## Workflow: Full rebuild (codegen + Android libs) - use after changing Rust function signatures
full-rebuild: codegen build-android
	@echo "✓ Full rebuild complete: Dart bindings and Android libs updated"

## Workflow: Rust implementation changes only (skip codegen)
rust-only: build-android
	@echo "✓ Android libs rebuilt. Ready for hot restart."

## Workflow: Full rebuild + Flutter run for development
android-dev: full-rebuild
	@flutter run
	@echo "Restarting Flutter app..."
	@echo "Run 'R' in flutter terminal to hot restart"

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
