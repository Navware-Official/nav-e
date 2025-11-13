// Bridge delegator: prefer generated flutter_rust_bridge bindings when
// available (from `lib/bridge/frb_generated.*`). If the generated binding
// doesn't expose the expected methods yet, fall back to the HTTP shim.

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
    // Try generated binding: either a static method on `gen.RustBridge` or
    // an instance method on `gen.RustBridge.instance`.
    try {
      final dynClass = gen.RustBridge;
      // Try static-style call first.
      try {
        final res = await (dynClass as dynamic).geocodeSearch(query, limit);
        if (res != null) return res as String;
      } catch (_) {
        // ignore and try instance
      }

      try {
        final inst = (dynClass as dynamic).instance;
        final res = await (inst as dynamic).geocodeSearch(query, limit);
        if (res != null) return res as String;
      } catch (_) {
        // ignore and fall back
      }
    } catch (_) {
      // If importing or referencing gen.RustBridge fails for any reason,
      // we'll just use the HTTP fallback below.
    }

    // HTTP fallback (Dart-only): query public Nominatim.
    final q = Uri.encodeQueryComponent(query);
    final l = limit ?? 10;
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&q=$q&limit=$l',
    );
    return await _httpGet(url);
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
    // If native binding isn't available, fall back to a public routing API
    // (OSRM demo server). This gives a quick way to get a route for testing.
    try {
      final start = '${startLon.toString()},${startLat.toString()}';
      final end = '${endLon.toString()},${endLat.toString()}';
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$start;$end?overview=full&geometries=geojson&steps=false&alternatives=false',
      );
      final body = await _httpGet(url);
      final Map<String, dynamic> obj = jsonDecode(body) as Map<String, dynamic>;
      if ((obj['code'] as String?) != 'Ok') throw Exception('OSRM error: ${obj['code']}');
      final routes = obj['routes'] as List?;
      if (routes == null || routes.isEmpty) throw Exception('No routes from OSRM');
      final r = routes.first as Map<String, dynamic>;
      final distance = (r['distance'] as num?)?.toDouble() ?? 0.0;
      final duration = (r['duration'] as num?)?.toDouble() ?? 0.0;
      final geometry = r['geometry'] as Map<String, dynamic>?;
      final coords = <List<double>>[];
      if (geometry != null && geometry['coordinates'] is List) {
        for (final c in (geometry['coordinates'] as List)) {
          if (c is List && c.length >= 2) {
            final lon = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            coords.add([lat, lon]);
          }
        }
      }

      final resObj = <String, dynamic>{
        'id': 'osrm-${DateTime.now().millisecondsSinceEpoch}',
        'polyline': null,
        'distance_m': distance,
        'duration_s': duration,
        'name': 'OSRM route',
        'waypoints': coords,
      };
      return jsonEncode(resObj);
    } catch (e) {
      throw Exception('navComputeRoute not available in generated bindings and OSRM fallback failed: $e');
    }
  }
}

Future<String> _httpGet(Uri url) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(url);
    req.headers.set('User-Agent', 'nav-e-app/1.0 (email@example.com)');
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
    return body;
  } finally {
    client.close();
  }
}
