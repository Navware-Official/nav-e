# nav-e 🧭

**The Navigation Engine** - A comprehensive Flutter-based navigation application designed as the core component of the Navware Navigation Companion ecosystem.

![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-blue.svg?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.8.1+-blue.svg?logo=dart)
![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20(planned)-lightgrey.svg)

## Overview

nav-e is a feature-rich navigation application built with Flutter that combines GPS tracking, Bluetooth device management, interactive mapping, and intelligent route planning. Designed for modern navigation needs, it provides a seamless experience across multiple platforms while maintaining high performance and reliability.

📚 **[Complete Documentation](docs/README.md)** - Architecture, development guides, and API references

## Releases

### 📦 Download & Installation

All stable releases are available through [GitHub Releases](https://github.com/Navware-Official/nav-e/releases) with pre-built APK files for Android devices.

#### 🔽 **Latest Release**
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/Navware-Official/nav-e)](https://github.com/Navware-Official/nav-e/releases/latest)
[![GitHub all releases](https://img.shields.io/github/downloads/Navware-Official/nav-e/total)](https://github.com/Navware-Official/nav-e/releases)

#### 📱 **Android Installation**

1. **Download**: Go to [Releases](https://github.com/Navware-Official/nav-e/releases) and download the latest `nav-e-android.apk`
2. **Enable Unknown Sources**: Go to Settings → Security → Enable "Install from unknown sources"
3. **Install**: Open the downloaded APK file and follow installation prompts
4. **Verify**: Check the app signature and version in app settings

####  **Release Notes**

Each release includes:
- ✨ **New Features**: Latest functionality additions
- 🐛 **Bug Fixes**: Resolved issues and improvements
- 🔧 **Technical Updates**: Dependency updates and optimizations
- ⚠️ **Breaking Changes**: Important migration notes (if any)

#### 🚀 **Release Schedule**

- **Stable Releases**: Monthly feature releases
- **Patch Releases**: As needed for critical fixes
- **Beta Releases**: Available for testing new features

For the latest development builds and pre-release versions, check the [Actions](https://github.com/Navware-Official/nav-e/actions) tab.


## Key Features

### 🗺️ **Advanced Mapping & Navigation**
- **Interactive Maps**: High-performance map rendering with multiple layer support
- **Real-time GPS Tracking**: Precise location tracking with heading information
- **Route Planning**: Intelligent pathfinding and navigation assistance
- **Custom Map Controls**: Intuitive controls for zoom, rotation, and recentering

### 📍 **Location Management**
- **Saved Places**: Persistent storage and management of favorite locations
- **Location Search**: Powerful geocoding-based search functionality
- **Location Preview**: Detailed previews of destinations before navigation

### 📱 **Device Integration**
- **Bluetooth Support**: Seamless connectivity with external navigation devices
- **Device Management**: Add, configure, and manage connected devices
- **Permission Handling**: Smart permission management for location and Bluetooth access

### 🎨 **User Experience**
- **Material Design**: Modern, intuitive interface following Material Design principles
- **Custom Typography**: Beautiful NeueHaasUnica and BitcountGridSingle fonts
- **Responsive Design**: Optimized for various screen sizes and orientations
- **Side Navigation**: Easy access to all app features through an elegant drawer

## 🛠️ Technical Architecture

### **State Management**
- **BLoC Pattern**: Robust state management using `flutter_bloc`
- **Event-Driven**: Clean separation of business logic and UI
- **Reactive Programming**: Stream-based data flow for real-time updates

### **Navigation & Routing**
- **GoRouter**: Declarative routing with deep linking support
- **Nested Navigation**: Complex navigation flows with proper state preservation

### **Data Management**
- **SQLite Database**: Local data persistence with `sqflite`
- **Repository Pattern**: Clean architecture with abstracted data sources
- **HTTP Client**: RESTful API integration for geocoding services

### **Core Dependencies**
```yaml
# State Management & Architecture
flutter_bloc: ^9.1.1
go_router: ^16.2.1
equatable: ^2.0.7

# Mapping & Location
flutter_map: ^8.2.1
latlong2: ^0.9.1
geolocator: ^14.0.2

# Connectivity & Hardware
flutter_blue_plus: ^1.35.5
permission_handler: ^12.0.1

# Data & Storage
sqflite: ^2.4.2
shared_preferences: ^2.5.3
http: ^1.5.0
```

## 🏗️ Project Structure

```
lib/
├── app/                     # App-level configuration
│   ├── app_router.dart     # Navigation setup
│   └── app_nav.dart        # Navigation utilities
├── core/                   # Core functionality
│   ├── bloc/              # Global state management
│   │   ├── location_bloc.dart
│   │   └── bluetooth/
│   ├── data/              # Data layer
│   │   ├── local/         # Local storage
│   │   └── remote/        # API clients
│   └── domain/            # Business logic
├── features/              # Feature modules
│   ├── home/             # Main dashboard
│   ├── map_layers/       # Mapping functionality
│   ├── device_management/ # Bluetooth devices
│   ├── saved_places/     # Location bookmarks
│   ├── search/           # Location search
│   ├── navigate/         # Navigation core
│   ├── plan_route/       # Route planning
│   └── settings/         # App configuration
└── widgets/              # Shared UI components
```

## Getting Started

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart SDK 3.8.1 or higher
- Android Studio / VS Code with Flutter extensions
- Physical device (recommended for GPS and Bluetooth testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone git@github.com:Navware-Official/nav-e.git
   cd nav-e
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
- Minimum SDK: API level varies (check `android/app/build.gradle`)
- Required permissions: Location, Bluetooth, Network

#### iOS
- Minimum iOS version: Check `ios/Podfile`
- Required Info.plist entries for location and Bluetooth usage

## 🧪 Testing

The project includes comprehensive testing coverage:

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

### Test Structure
- **Unit Tests**: Core business logic and repositories
- **BLoC Tests**: State management testing with `bloc_test`
- **Widget Tests**: UI component testing
- **Integration Tests**: End-to-end workflow testing

## 📱 Supported Platforms

- ✅ **Android** - Primary platform with full feature support
- X **iOS** - Planned

## 🔧 Development

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` for static analysis

### Developer mode

A hidden developer mode can be enabled for device communication and future developer features:

- **Enable/disable:** In the app, go to **Settings → About** and tap the **build/version info** (e.g. "App Version", version text) **7 times** quickly. A SnackBar confirms "Developer mode enabled" or "Developer mode disabled". The setting is persisted (SharedPreferences) across app restarts.
- **When developer mode is ON:** The plan-route **Send to Device** button opens the **Device Communication Debug** screen (device picker, send route/heartbeat, event log).
- **When developer mode is OFF:** **Send to Device** sends the current route to the first connected device immediately and shows a loading bar until done (no developer screen).

This toggle can be reused for other developer-only features later.

### Contributing
Please read [CONTRIBUTING.MD](CONTRIBUTING.MD) for details on our development process and pull request guidelines.

### Commit Convention
We use [Conventional Commits](https://www.conventionalcommits.org/) for PR titles:
- `feat:` for new features
- `fix:` for bug fixes
- `chore:` for maintenance tasks

## 📄 License

This project uses [GPL-3.0 license](https://github.com/Navware-Official/nav-e?tab=GPL-3.0-1-ov-file#readme)

## 🔗 Related Projects

Part of the **Navware Navigation Companion** device - a comprehensive navigation solution designed for modern mobility needs.

---

**Built with ❤️ using Flutter**
