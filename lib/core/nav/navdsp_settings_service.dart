import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nav_e/bridge/lib.dart' as rust_api;

class NavDspSettingsService {
  static const _tokenKey = 'navdsp_token';
  static const _geoEnabledKey = 'navdsp_geocoding_enabled';
  static const _overrideUrlKey = 'navdsp_override_url';

  /// Apply saved config to the Rust layer. Call once on startup after initializeDatabase.
  /// [compiledBaseUrl] comes from --dart-define=NAV_DSP_URL (defaults to data.navware.org).
  static Future<void> rehydrate(String compiledBaseUrl) async {
    final prefs = await SharedPreferences.getInstance();

    // In debug builds, allow a runtime URL override (useful for physical devices).
    String baseUrl = compiledBaseUrl;
    if (kDebugMode) {
      final override = prefs.getString(_overrideUrlKey);
      if (override != null && override.isNotEmpty) {
        baseUrl = override;
      }
    }

    final token = prefs.getString(_tokenKey);
    final geoEnabled = prefs.getBool(_geoEnabledKey) ?? false;

    await rust_api.setNavdspConfig(
      baseUrl: baseUrl,
      token: (token == null || token.isEmpty) ? null : token,
      geocodingEnabled: geoEnabled,
    );
  }

  /// Update config at runtime (called from settings screen).
  static Future<void> configure({
    required String compiledBaseUrl,
    String? token,
    required bool geocodingEnabled,
    String? overrideUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token ?? '');
    await prefs.setBool(_geoEnabledKey, geocodingEnabled);
    if (kDebugMode) {
      await prefs.setString(_overrideUrlKey, overrideUrl ?? '');
    }

    String baseUrl = compiledBaseUrl;
    if (kDebugMode && overrideUrl != null && overrideUrl.isNotEmpty) {
      baseUrl = overrideUrl;
    }

    await rust_api.setNavdspConfig(
      baseUrl: baseUrl,
      token: (token == null || token.isEmpty) ? null : token,
      geocodingEnabled: geocodingEnabled,
    );
  }

  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return (token == null || token.isEmpty) ? null : token;
  }

  static Future<bool> isGeocodingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_geoEnabledKey) ?? false;
  }

  static Future<String?> getOverrideUrl() async {
    if (!kDebugMode) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_overrideUrlKey);
  }
}
