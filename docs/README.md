# Nav-E Documentation

Welcome to the Nav-E documentation! This directory contains all technical documentation for the project.

## 📚 Documentation Structure

### 🏗️ Architecture (`architecture/`)
System design, patterns, and architectural decisions:
- **[Overview](architecture/overview.md)** - System architecture, DDD/Hexagonal design, CQRS pattern, and module organization

### 📖 Developer Guides (`guides/`)
Step-by-step guides for common development tasks:
- **[Flutter-Rust Bridge](guides/flutter-rust-bridge.md)** - FFI integration between Flutter and Rust
- **[Device Communication](guides/device-communication.md)** - Sending routes to devices via BLE
- **[Testing](guides/testing.md)** - Testing strategy and test organization

### 🦀 Rust Documentation (`rust/`)
Native Rust codebase documentation:
- **[Overview](rust/overview.md)** - Rust project structure, crates, and development workflow
- **[Device Comm](rust/device-comm.md)** - BLE communication protocol and frame handling
- **[Protobuf](rust/protobuf.md)** - Protocol Buffer definitions and code generation

## 🚀 Quick Start

### New Developers
1. Start with [Architecture Overview](architecture/overview.md) to understand the system design
2. Read [Rust Overview](rust/overview.md) for Rust development setup
3. Check [Testing Guide](guides/testing.md) for testing guidelines

### Working with Device Communication
1. Read [Device Communication Guide](guides/device-communication.md) for Flutter integration
2. Understand the [Device Comm Protocol](rust/device-comm.md) for low-level details
3. Review [Protobuf](rust/protobuf.md) message definitions
4. Check [Flutter-Rust Bridge](guides/flutter-rust-bridge.md) for FFI integration
2. Run `make migrate-new` to create a migration
3. Follow [Migrations: Release Process](migrations-release.md) for releases

### For Integration Work
1. Understand [Flutter-Rust Bridge](flutter-rust-bridge.md)
2. Review [Protobuf](protobuf.md) for device communication

## 📖 Additional Resources

- **[Main README](../README.md)** - Project overview and setup
- **[Makefile](../Makefile)** - Build commands and development tools
- **[Contributing Guidelines](../CONTRIBUTING.MD)** - How to contribute

## 🔧 Development Commands

```bash
# Build & Development
make codegen            # Regenerate Rust-Dart bindings
make build-native       # Build Rust native code
make test               # Run Flutter tests

# Database Migrations
make migrate-new        # Create a new migration
make migrate-status     # Check migration status

# Code Quality
make fmt                # Format Rust code
```

## 📝 Documentation Standards

When adding new documentation:
- Use clear, descriptive titles
- Include code examples where helpful
- Keep content up-to-date with code changes
- Add links to this index

## 🗺️ Document Organization

```
docs/
├── README.md                          # This index file
├── architecture/
│   └── overview.md                    # System architecture and design patterns
├── guides/
│   ├── device-communication.md        # BLE device communication guide
│   ├── flutter-rust-bridge.md         # FFI integration between Flutter/Rust
│   └── testing.md                     # Testing strategy and guidelines
├── reference/                         # (Reserved for API references)
└── rust/
    ├── overview.md                    # Rust codebase structure
    ├── device-comm.md                 # BLE protocol and frame handling
    └── protobuf.md                    # Protocol buffer definitions
```

---

For questions or suggestions about documentation, please open an issue or contact the team.
