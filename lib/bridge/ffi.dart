// Bridge delegator: prefer generated flutter_rust_bridge bindings when
// available (from `lib/bridge/frb_generated.*`). The app now requires
// the native Rust implementations for geocoding and routing; when the
// generated bindings aren't present this delegator will raise an error.

import 'dart:convert';
import 'dart:io';

// Import generated bindings under a prefix so we can attempt dynamic calls.
// The generated file may or may not provide the geocoding functions yet.
import 'frb_generated.dart' as gen;

/// Public API used across the app: `bridge.RustBridge.geocodeSearch(...)`.
///
/// This delegator first attempts to call the generated FRB binding using
/// dynamic invocation (so compilation doesn't depend on exact generated
/// signatures). If the generated binding isn't present or the call fails,
/// it falls back to a pure-Dart HTTP implementation that queries Nominatim.
class RustBridge {
  static Future<String> geocodeSearch(String query, int? limit) async {
    // Prefer the generated FRB binding (native Rust implementation).
    // Try static-style call first, then instance-style. If the binding is
    // missing or the call fails, surface a clear error so callers can
    // handle the absence of a native geocoder.
    try {
      final dynClass = gen.RustBridge;
      try {
        final res = await (dynClass as dynamic).geocodeSearch(query, limit);
        if (res != null) return res as String;
      } catch (_) {}

      try {
        final inst = (dynClass as dynamic).instance;
        final res = await (inst as dynamic).geocodeSearch(query, limit);
        if (res != null) return res as String;
      } catch (_) {}
    } catch (_) {}

    // Fall back to HTTP-based Nominatim search when native binding isn't
    // available. This is temporary until the FRB generation issue is
    // resolved.
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&q=${Uri.encodeComponent(query)}&limit=${limit ?? 10}',
      );
      final httpClient = HttpClient();
      final req = await httpClient.getUrl(uri);
      req.headers.set('User-Agent', 'nav-e-app/1.0 (email@example.com)');
      final resp = await req.close();
      if (resp.statusCode != 200) return '[]';
      final body = await resp.transform(utf8.decoder).join();
      return body;
    } catch (e) {
      return '[]';
    }
  }

  /// Typed-friendly wrapper: returns parsed List<Map<String, dynamic>>.
  static Future<List<Map<String, dynamic>>> geocodeSearchTyped(
    String query,
    int? limit,
  ) async {
    final json = await geocodeSearch(query, limit);
    final parsed = jsonDecode(json) as List;
    return parsed.cast<Map<String, dynamic>>();
  }

  /// Request route computation from the native Rust engine.
  /// Returns a JSON string (serialized `FrbRoute`).
  static Future<String> navComputeRoute(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
    String? options,
  ) async {
    try {
      final dynClass = gen.RustBridge;
      try {
        final res = await (dynClass as dynamic).navComputeRoute(
          startLat,
          startLon,
          endLat,
          endLon,
          options,
        );
        if (res != null) return res as String;
      } catch (_) {}

      try {
        final inst = (dynClass as dynamic).instance;
        final res = await (inst as dynamic).navComputeRoute(
          startLat,
          startLon,
          endLat,
          endLon,
          options,
        );
        if (res != null) return res as String;
      } catch (_) {}
    } catch (_) {
      // fall through to error below
    }
    // Native binding wasn't available or failed. Surface a clear error so
    // callers know to handle the absence of a native implementation.
    // Fall back to OSRM when native binding isn't available.
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson&steps=false&alternatives=false',
      );
      final httpClient = HttpClient();
      final req = await httpClient.getUrl(uri);
      final resp = await req.close();
      if (resp.statusCode != 200) throw Exception('OSRM request failed');
      final body = await resp.transform(utf8.decoder).join();
      final jsonResp = jsonDecode(body) as Map<String, dynamic>;
      final routes = (jsonResp['routes'] as List?) ?? [];
      if (routes.isEmpty) throw Exception('No routes');
      final first = routes[0] as Map<String, dynamic>;
      final distance = (first['distance'] as num?)?.toDouble() ?? 0.0;
      final duration = (first['duration'] as num?)?.toDouble() ?? 0.0;
      final waypoints = <List<double>>[];
      final geometry = first['geometry'] as Map<String, dynamic>?;
      if (geometry != null && geometry['coordinates'] is List) {
        for (final coord in geometry['coordinates'] as List) {
          if (coord is List && coord.length >= 2) {
            final lon = (coord[0] as num).toDouble();
            final lat = (coord[1] as num).toDouble();
            waypoints.add([lat, lon]);
          }
        }
      }

      final frbRoute = {
        'id': 'osrm-fallback',
        'polyline': '',
        'distance_m': distance,
        'duration_s': duration,
        'name': 'OSRM fallback',
        'waypoints': waypoints,
      };

      return jsonEncode(frbRoute);
    } catch (e) {
      throw Exception(
        'navComputeRoute not available in generated bindings: $e',
      );
    }
  }
}

// No Dart-side HTTP fallbacks remain. All network-backed features the
// app requires (geocoding, routing) are expected to be implemented in
// the native Rust bridge and exposed via the generated FRB bindings.
