import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:nav_e/core/domain/repositories/offline_regions_repository.dart';
import 'package:nav_e/features/offline_maps/data/local_tile_server.dart';

const String _defaultStyleAsset = 'assets/styles/custom_style.json';
const String _darkStyleAsset = 'assets/styles/custom_style_dark.json';
const String _vectorSourceId = 'openmaptiles';

/// Resolves map style JSON for an offline region: starts local tile server and
/// injects the local tile URL into the vector source.
/// For full offline, bundle glyphs (e.g. Noto) as assets and set "glyphs" in the
/// style to asset://... so labels work without network.
class OfflineMapStyleResolver {
  OfflineMapStyleResolver(this._repository);

  final IOfflineRegionsRepository _repository;
  final Map<String, LocalTileServer> _servers = {};

  /// Returns style JSON string for the given offline region id, or null if not found.
  /// Starts a local HTTP server for the region's MBTiles and replaces the vector
  /// source in the base style with the local tile URL.
  /// [useDarkStyle] uses the dark style variant (same layers, different colors).
  Future<String?> getStyleString(
    String regionId, {
    bool useDarkStyle = false,
  }) async {
    final region = await _repository.getById(regionId);
    if (region == null) return null;

    final path = await _repository.getAbsolutePath(region);
    final server = _servers[regionId] ?? await LocalTileServer.start(path);
    _servers[regionId] = server;

    final styleAsset = useDarkStyle ? _darkStyleAsset : _defaultStyleAsset;
    final baseStyle = await rootBundle.loadString(styleAsset);
    final map = jsonDecode(baseStyle) as Map<String, dynamic>;
    final sources = map['sources'] as Map<String, dynamic>? ?? {};
    final tileUrl = '${server.baseUrl}/tiles/{z}/{x}/{y}.pbf';
    sources[_vectorSourceId] = {
      'type': 'vector',
      'tiles': [tileUrl],
      'minzoom': region.minZoom,
      'maxzoom': region.maxZoom,
    };
    map['sources'] = sources;
    return jsonEncode(map);
  }

  /// Stop the server for [regionId] if running. Call when user switches away from offline.
  Future<void> stopServer(String regionId) async {
    final server = _servers.remove(regionId);
    if (server != null) await server.stop();
  }

  /// Stop all servers.
  Future<void> stopAll() async {
    for (final server in _servers.values) {
      await server.stop();
    }
    _servers.clear();
  }
}
