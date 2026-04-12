import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nav_e/core/nav/navdsp_settings_service.dart';

/// Stored credential keys.
const _kToken = 'navware_token';
const _kEmail = 'navware_email';
const _kTier = 'navware_tier';

class NavwareUser {
  final String email;
  final String tier;
  const NavwareUser({required this.email, required this.tier});
}

class NavwareAuthException implements Exception {
  final String message;
  const NavwareAuthException(this.message);
  @override
  String toString() => message;
}

class NavwareAuthService {
  static String _baseUrl() {
    // In debug builds, prefer the stored override URL.
    // Falls back to the compiled default (NAV_DSP_URL --dart-define).
    return const String.fromEnvironment(
      'NAV_DSP_URL',
      defaultValue: 'https://data.navware.org',
    );
  }

  static Future<String> _resolvedBaseUrl() async {
    if (kDebugMode) {
      final override = await NavDspSettingsService.getOverrideUrl();
      if (override != null && override.isNotEmpty) return override;
    }
    return _baseUrl();
  }

  // ── Email / password ─────────────────────────────────────────────────────────

  static Future<NavwareUser> login(String email, String password) async {
    final base = await _resolvedBaseUrl();
    final response = await http
        .post(
          Uri.parse('$base/v1/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) {
      throw const NavwareAuthException('Incorrect email or password.');
    }
    if (response.statusCode != 200) {
      final body = _tryDecodeError(response.body);
      throw NavwareAuthException(
        body ?? 'Login failed (${response.statusCode})',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    final tier = data['tier'] as String? ?? 'free';

    await _persist(token: token, email: email.trim(), tier: tier);
    await _applyTokenToRust(token);

    return NavwareUser(email: email.trim(), tier: tier);
  }

  static Future<NavwareUser> register(String email, String password) async {
    final base = await _resolvedBaseUrl();
    final response = await http
        .post(
          Uri.parse('$base/v1/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 409) {
      throw const NavwareAuthException(
        'An account with this email already exists.',
      );
    }
    if (response.statusCode != 201) {
      final body = _tryDecodeError(response.body);
      throw NavwareAuthException(
        body ?? 'Registration failed (${response.statusCode})',
      );
    }

    // Auto-login after registration.
    return login(email, password);
  }

  // ── Passkeys ─────────────────────────────────────────────────────────────────

  /// Full passkey registration flow: challenge → biometric → verify → JWT.
  static Future<NavwareUser> registerWithPasskey(String email) async {
    final base = await _resolvedBaseUrl();
    final trimmed = email.trim();

    // Step 1: Get the WebAuthn creation challenge from the server.
    final startResponse = await http
        .post(
          Uri.parse('$base/v1/auth/passkey/register/start'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': trimmed}),
        )
        .timeout(const Duration(seconds: 10));

    if (startResponse.statusCode != 200) {
      final body = _tryDecodeError(startResponse.body);
      throw NavwareAuthException(
        body ??
            'Could not start passkey registration (${startResponse.statusCode})',
      );
    }

    // The server wraps the challenge in { "publicKey": { ... } }
    final serverJson = jsonDecode(startResponse.body) as Map<String, dynamic>;
    final publicKey = serverJson['publicKey'] as Map<String, dynamic>;

    // Step 2: Create the passkey on device (triggers biometric prompt).
    final RegisterResponseType credential;
    try {
      final request = RegisterRequestType.fromJson(publicKey);
      credential = await PasskeyAuthenticator().register(request);
    } on PasskeyAuthCancelledException {
      throw const NavwareAuthException('Passkey registration cancelled.');
    } on DomainNotAssociatedException catch (e) {
      throw NavwareAuthException(
        'Domain not associated (${e.message}). '
        'Digital Asset Links must be configured for this device.',
      );
    } on DeviceNotSupportedException {
      throw const NavwareAuthException(
        'This device does not support passkeys.',
      );
    } catch (e) {
      throw NavwareAuthException('Passkey error: $e');
    }

    // Step 3: Verify the authenticator response with the server.
    final finishResponse = await http
        .post(
          Uri.parse('$base/v1/auth/passkey/register/finish'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': trimmed,
            'credential': credential.toJson(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (finishResponse.statusCode != 200) {
      final body = _tryDecodeError(finishResponse.body);
      throw NavwareAuthException(
        body ?? 'Passkey registration failed (${finishResponse.statusCode})',
      );
    }

    final data = jsonDecode(finishResponse.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    final tier = data['tier'] as String? ?? 'free';

    await _persist(token: token, email: trimmed, tier: tier);
    await _applyTokenToRust(token);
    return NavwareUser(email: trimmed, tier: tier);
  }

  /// Full passkey authentication flow: challenge → biometric → verify → JWT.
  static Future<NavwareUser> loginWithPasskey(String email) async {
    final base = await _resolvedBaseUrl();
    final trimmed = email.trim();

    // Step 1: Get the WebAuthn authentication challenge from the server.
    final startResponse = await http
        .post(
          Uri.parse('$base/v1/auth/passkey/authenticate/start'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': trimmed}),
        )
        .timeout(const Duration(seconds: 10));

    if (startResponse.statusCode == 400) {
      final body = _tryDecodeError(startResponse.body);
      throw NavwareAuthException(
        body ?? 'No passkey registered for this account.',
      );
    }
    if (startResponse.statusCode != 200) {
      final body = _tryDecodeError(startResponse.body);
      throw NavwareAuthException(
        body ??
            'Could not start passkey authentication (${startResponse.statusCode})',
      );
    }

    final serverJson = jsonDecode(startResponse.body) as Map<String, dynamic>;
    final publicKey = serverJson['publicKey'] as Map<String, dynamic>;

    // Step 2: Assert with a stored passkey (triggers biometric prompt).
    final AuthenticateResponseType assertion;
    try {
      final request = AuthenticateRequestType.fromJson(publicKey);
      assertion = await PasskeyAuthenticator().authenticate(request);
    } on PasskeyAuthCancelledException {
      throw const NavwareAuthException('Passkey authentication cancelled.');
    } on NoCredentialsAvailableException {
      throw const NavwareAuthException(
        'No passkey found on this device. Register a passkey first.',
      );
    } on DomainNotAssociatedException catch (e) {
      throw NavwareAuthException(
        'Domain not associated (${e.message}). '
        'Digital Asset Links must be configured for this device.',
      );
    } on DeviceNotSupportedException {
      throw const NavwareAuthException(
        'This device does not support passkeys.',
      );
    } catch (e) {
      throw NavwareAuthException('Passkey error: $e');
    }

    // Step 3: Verify the assertion with the server.
    final finishResponse = await http
        .post(
          Uri.parse('$base/v1/auth/passkey/authenticate/finish'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': trimmed,
            'credential': assertion.toJson(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (finishResponse.statusCode == 401) {
      throw const NavwareAuthException('Passkey verification failed.');
    }
    if (finishResponse.statusCode != 200) {
      final body = _tryDecodeError(finishResponse.body);
      throw NavwareAuthException(
        body ?? 'Passkey authentication failed (${finishResponse.statusCode})',
      );
    }

    final data = jsonDecode(finishResponse.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    final tier = data['tier'] as String? ?? 'free';

    await _persist(token: token, email: trimmed, tier: tier);
    await _applyTokenToRust(token);
    return NavwareUser(email: trimmed, tier: tier);
  }

  // ── Sign out ─────────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kEmail);
    await prefs.remove(_kTier);
    await _applyTokenToRust(null);
  }

  // ── Stored state ─────────────────────────────────────────────────────────────

  /// Returns the cached user from SharedPreferences, or null if not logged in.
  static Future<NavwareUser?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    final email = prefs.getString(_kEmail);
    final tier = prefs.getString(_kTier);
    if (token == null || token.isEmpty || email == null) return null;
    return NavwareUser(email: email, tier: tier ?? 'free');
  }

  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  /// Call on startup to restore the token into the Rust layer.
  static Future<void> rehydrate() async {
    final token = await getStoredToken();
    if (token != null && token.isNotEmpty) {
      await _applyTokenToRust(token);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static Future<void> _persist({
    required String token,
    required String email,
    required String tier,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kEmail, email);
    await prefs.setString(_kTier, tier);
  }

  static Future<void> _applyTokenToRust(String? token) async {
    final geoEnabled = await NavDspSettingsService.isGeocodingEnabled();
    final compiledUrl = const String.fromEnvironment(
      'NAV_DSP_URL',
      defaultValue: 'https://data.navware.org',
    );
    await NavDspSettingsService.configure(
      compiledBaseUrl: compiledUrl,
      token: token,
      geocodingEnabled: geoEnabled,
    );
  }

  static String? _tryDecodeError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
