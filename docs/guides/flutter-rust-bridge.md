# Flutter Rust Bridge Integration Notes

## Current Status

The Flutter Rust Bridge code generation includes some internal types (application commands/queries/handlers and infrastructure adapters) that are implementation details and shouldn't be used from Flutter.

## Solution

**Use ONLY the public API from `api_v2.dart`**:

```dart
import 'package:nav_e/bridge/api_v2.dart' as api;

// Route calculation
final json = await api.calculateRoute(waypoints: waypoints);

// Geocoding
final json = await api.geocodeSearch(query: query, limit: limit);

// Navigation
final sessionJson = await api.startNavigationSession(
  waypoints: waypoints,
  currentPosition: currentPosition,
);
await api.updateNavigationPosition(sessionId: id, latitude: lat, longitude: lon);
await api.pauseNavigation(sessionId: id);
await api.resumeNavigation(sessionId: id);
await api.stopNavigation(sessionId: id, completed: true);
```

## Errors in Generated Code

The analyzer errors in `lib/bridge/` for internal types (application/, infrastructure/) can be ignored:
- These files are suppressed by `lib/bridge/analysis_options.yaml`
- DO NOT import or use types from these directories
- Stick to `api_v2.dart` functions only

## Regenerating Bridge

Always use:
```bash
make codegen
```

This runs the post-codegen cleanup script automatically.
