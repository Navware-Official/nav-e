import 'dart:convert';

import 'package:flutter/services.dart';

const _channel = MethodChannel('org.navware.nav_e/route_import');

/// Returns the URI from "Open with" / "Share with" intent if present, then clears it.
Future<String?> getPendingImportUri() async {
  final uri = await _channel.invokeMethod<String>('getPendingImportUri');
  return uri;
}

/// Reads file bytes from a content URI (e.g. from Android share). Returns decoded bytes.
Future<List<int>> readFileFromUri(String uri) async {
  final base64 = await _channel.invokeMethod<String>('readFileFromUri', {
    'uri': uri,
  });
  if (base64 == null || base64.isEmpty) {
    throw Exception('No data from URI');
  }
  return base64Decode(base64);
}
