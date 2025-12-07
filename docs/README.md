# Nav-E Documentation

Welcome to the Nav-E documentation! This directory contains all technical documentation for the project.

## 📚 Documentation Index

### Architecture & Design
- **[Architecture](architecture.md)** - System architecture, DDD/Hexagonal design, and module organization
- **[Native Rust](native-rust.md)** - Rust codebase structure and development guide

### Database & Migrations
- **[Migrations: Developer Guide](migrations-developer-guide.md)** - Creating and managing database migrations
- **[Migrations: Release Process](migrations-release.md)** - Migration workflow for releases and deployments

### Flutter & Dart
- **[Flutter-Rust Bridge](flutter-rust-bridge.md)** - FFI integration between Flutter and Rust
- **[Testing](testing.md)** - Testing strategy and test organization

### Communication
- **[Protobuf](protobuf.md)** - Protocol Buffer definitions and code generation

## 🚀 Quick Start Guides

### For Developers
1. Read [Architecture](architecture.md) to understand the system design
2. Check [Native Rust](native-rust.md) for Rust development setup
3. Review [Testing](testing.md) for testing guidelines

### For Database Changes
1. Read [Migrations: Developer Guide](migrations-developer-guide.md)
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
├── README.md                          # This file
├── architecture.md                    # System architecture
├── native-rust.md                     # Rust development
├── flutter-rust-bridge.md             # FFI integration
├── migrations-developer-guide.md      # Creating migrations
├── migrations-release.md              # Release workflow
├── protobuf.md                        # Protocol buffers
└── testing.md                         # Testing guide
```

---

For questions or suggestions about documentation, please open an issue or contact the team.
