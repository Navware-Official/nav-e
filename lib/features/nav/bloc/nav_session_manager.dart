import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:nav_e/bridge/lib.dart' as api;
import '../models/nav_models.dart';

/// Delegates FFI calls for navigation session lifecycle.
///
/// All methods are fire-and-forget wrappers — errors are swallowed because
/// session state is non-fatal: the app continues client-side if Rust is
/// unavailable.
class NavSessionManager {
  /// Starts a new Rust session for [routePoints]. Returns the session ID or
  /// `null` on error or if fewer than two points are provided.
  Future<String?> startSession(List<LatLng> routePoints) async {
    if (routePoints.length < 2) return null;
    try {
      final start = routePoints.first;
      final end = routePoints.last;
      final session = await api.startNavigationSession(
        waypoints: [
          (start.latitude, start.longitude),
          (end.latitude, end.longitude),
        ],
        currentPosition: (start.latitude, start.longitude),
      );
      return session.id;
    } catch (_) {
      return null;
    }
  }

  /// Loads turn-by-turn cues for [sessionId].
  ///
  /// Returns an empty list on error. Uses [currentPosition] as the cue location
  /// fallback.
  Future<List<NavCue>> loadTurnFeed(
    String sessionId,
    LatLng? currentPosition,
  ) async {
    try {
      final steps = await api.getRouteSteps(sessionId: sessionId);
      return steps.asMap().entries.map((entry) {
        final s = entry.value;
        return NavCue(
          id: 'step_${entry.key}',
          instruction: NavSessionManager._instructionFor(s.kind, s.streetName),
          distanceToCueM: s.distanceToNextM,
          distanceToCueText: NavSessionManager._formatDistanceText(
            s.distanceToNextM,
          ),
          location: currentPosition ?? const LatLng(0, 0),
          maneuver: s.kind,
          streetName: s.streetName,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> stop(String sessionId) async {
    try {
      await api.stopNavigation(sessionId: sessionId);
    } catch (_) {}
  }

  Future<void> pause(String sessionId) async {
    try {
      await api.pauseNavigation(sessionId: sessionId);
    } catch (_) {}
  }

  Future<void> resume(String sessionId) async {
    try {
      await api.resumeNavigation(sessionId: sessionId);
    } catch (_) {}
  }

  /// Calculates a reroute from [origin] to [destination].
  ///
  /// Returns a record with the new polyline points and a new session ID.
  /// Throws on error — callers should catch and handle gracefully.
  Future<({List<LatLng> points, String sessionId})> reroute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final route = await api.calculateRoute(
      waypoints: [
        (origin.latitude, origin.longitude),
        (destination.latitude, destination.longitude),
      ],
    );
    final points = (jsonDecode(route.polylineJson) as List)
        .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
    final session = await api.startNavigationSession(
      waypoints: [
        (origin.latitude, origin.longitude),
        (destination.latitude, destination.longitude),
      ],
      currentPosition: (origin.latitude, origin.longitude),
    );
    return (points: points, sessionId: session.id);
  }

  /// Builds a [NavCue] from primitive fields. Useful in callers that cannot
  /// reference [DerivedInstructionDto] directly.
  static NavCue buildCue({
    required String id,
    required String kind,
    String? streetName,
    required double distanceToNextM,
    required LatLng location,
  }) {
    return NavCue(
      id: id,
      instruction: _instructionFor(kind, streetName),
      distanceToCueM: distanceToNextM,
      distanceToCueText: _formatDistanceText(distanceToNextM),
      location: location,
      maneuver: kind,
      streetName: streetName,
    );
  }

  static String _instructionFor(String kind, String? streetName) {
    final base = switch (kind) {
      'turn_left' => 'Turn left',
      'turn_right' => 'Turn right',
      'slight_left' => 'Slight left',
      'slight_right' => 'Slight right',
      'sharp_left' => 'Turn sharp left',
      'sharp_right' => 'Turn sharp right',
      'depart' => 'Depart',
      'arrive' => 'You have arrived',
      _ => 'Continue',
    };
    if (streetName != null && streetName.isNotEmpty) {
      return '$base onto $streetName';
    }
    return base;
  }

  static String _formatDistanceText(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }
}
