import 'dart:convert';

import 'package:nav_e/bridge/lib.dart' as rust;
import 'package:nav_e/core/domain/entities/offline_region.dart';
import 'package:nav_e/core/domain/repositories/offline_regions_repository.dart';
import 'package:path/path.dart' as path;

/// Rust-backed offline regions repository.
/// Registry and download logic live in Rust; this is a thin Dart wrapper for UI.
/// Run `make codegen` after changing Rust offline region APIs to regenerate the bridge.
class OfflineRegionsRepositoryRust implements IOfflineRegionsRepository {
  @override
  Future<String> getStoragePath() async {
    return rust.getOfflineRegionsStoragePath();
  }

  @override
  Future<List<OfflineRegion>> getAll() async {
    final json = rust.getAllOfflineRegions();
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => OfflineRegion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OfflineRegion?> getById(String id) async {
    final json = rust.getOfflineRegionById(id: id);
    if (json == 'null') return null;
    final data = jsonDecode(json) as Map<String, dynamic>?;
    if (data == null) return null;
    return OfflineRegion.fromJson(data);
  }

  @override
  Future<void> add(OfflineRegion region) async {
    // Regions are added by Rust when downloading; no direct insert from Dart.
    throw UnsupportedError('Use downloadRegion() to add regions');
  }

  @override
  Future<void> delete(String id) async {
    rust.deleteOfflineRegion(id: id);
  }

  @override
  Future<OfflineRegion?> getRegionForViewport(
    double north,
    double south,
    double east,
    double west,
  ) async {
    final json = rust.getOfflineRegionForViewport(
      north: north,
      south: south,
      east: east,
      west: west,
    );
    if (json == 'null') return null;
    final data = jsonDecode(json) as Map<String, dynamic>?;
    if (data == null) return null;
    return OfflineRegion.fromJson(data);
  }

  @override
  Future<String> getAbsolutePath(OfflineRegion region) async {
    final base = await getStoragePath();
    return path.join(base, region.relativePath);
  }

  @override
  Future<OfflineRegion?> downloadRegion({
    required String name,
    required double north,
    required double south,
    required double east,
    required double west,
    required int minZoom,
    required int maxZoom,
    String? tileUrlTemplate,
    void Function(int done, int total, int zoom)? onProgress,
  }) async {
    // onProgress ignored: download runs in Rust without streaming progress for now
    try {
      final json = rust.downloadOfflineRegion(
        name: name,
        north: north,
        south: south,
        east: east,
        west: west,
        minZoom: minZoom,
        maxZoom: maxZoom,
        tileUrlTemplate: tileUrlTemplate,
      );
      final data = jsonDecode(json) as Map<String, dynamic>;
      return OfflineRegion.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
