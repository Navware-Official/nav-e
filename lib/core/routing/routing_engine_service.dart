import 'package:nav_e/bridge/lib.dart' as api;
import 'package:shared_preferences/shared_preferences.dart';

enum RoutingEngine { osrm, valhalla, googleRoutes, onDevice }

/// Persists and provides the user's preferred routing engine selection.
class RoutingEngineService {
  static const _key = 'routing_engine';
  static const defaultEngine = RoutingEngine.osrm;

  /// Returns the stored engine, falling back to [defaultEngine].
  static Future<RoutingEngine> getDefaultEngine() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null) {
      try {
        return RoutingEngine.values.byName(stored);
      } catch (_) {}
    }
    return defaultEngine;
  }

  /// Persists [engine] as the default and notifies the Rust layer.
  static Future<void> setDefaultEngine(RoutingEngine engine) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, engine.name);
    await api.setRoutingEngine(engine: engine.name);
  }

  static String displayName(RoutingEngine engine) => switch (engine) {
    RoutingEngine.osrm => 'OSRM',
    RoutingEngine.valhalla => 'Valhalla',
    RoutingEngine.googleRoutes => 'Google Routes',
    RoutingEngine.onDevice => 'On-Device',
  };

  /// OSRM and Valhalla are available. Google Routes requires an API key at build time.
  /// On-Device is not yet implemented.
  static bool isAvailable(RoutingEngine engine) => switch (engine) {
    RoutingEngine.osrm => true,
    RoutingEngine.valhalla => true,
    RoutingEngine.googleRoutes => const String.fromEnvironment(
      'GOOGLE_ROUTES_KEY',
    ).isNotEmpty,
    RoutingEngine.onDevice => false,
  };
}
