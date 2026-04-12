import 'package:shared_preferences/shared_preferences.dart';

/// Persists user-facing navigation preferences.
class NavSettingsService {
  static const _keyOffRouteThreshold = 'nav_off_route_threshold_m';
  static const defaultOffRouteThresholdM = 50.0;

  /// Valid choices shown in Settings.
  static const offRouteOptions = [20.0, 50.0, 100.0, 200.0];

  /// Returns the stored off-route threshold, or [defaultOffRouteThresholdM].
  static Future<double> getOffRouteThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getDouble(_keyOffRouteThreshold);
    if (stored != null && offRouteOptions.contains(stored)) return stored;
    return defaultOffRouteThresholdM;
  }

  /// Persists [thresholdM]. Must be one of [offRouteOptions].
  static Future<void> setOffRouteThreshold(double thresholdM) async {
    assert(offRouteOptions.contains(thresholdM));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyOffRouteThreshold, thresholdM);
  }

  static const _keyRoutingEngine = 'nav_routing_engine';
  static const defaultRoutingEngine = 'osrm';

  /// Valid engine identifiers and their display labels.
  static const routingEngines = {
    'osrm': 'OSRM (default)',
    'valhalla': 'Valhalla',
    'googleRoutes': 'Google Routes',
  };

  static Future<String> getRoutingEngine() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyRoutingEngine);
    if (stored != null && routingEngines.containsKey(stored)) return stored;
    return defaultRoutingEngine;
  }

  static Future<void> setRoutingEngine(String engine) async {
    assert(routingEngines.containsKey(engine));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRoutingEngine, engine);
  }
}
