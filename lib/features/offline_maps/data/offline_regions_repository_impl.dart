import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:nav_e/core/domain/entities/offline_region.dart';
import 'package:nav_e/core/domain/repositories/offline_regions_repository.dart';

const String _subdir = 'offline_regions';
const String _registryFileName = 'regions.json';

/// File-based implementation: registry in regions.json, tile dirs (region_\<id\>/z/x/y.pbf) in same dir.
class OfflineRegionsRepositoryImpl implements IOfflineRegionsRepository {
  String? _storagePath;

  Future<String> _ensureStoragePath() async {
    if (_storagePath != null) return _storagePath!;
    final dir = await getApplicationDocumentsDirectory();
    final storageDir = Directory(path.join(dir.path, _subdir));
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }
    _storagePath = storageDir.path;
    return _storagePath!;
  }

  File _registryFile(String basePath) =>
      File(path.join(basePath, _registryFileName));

  Future<List<OfflineRegion>> _readRegistry() async {
    final basePath = await _ensureStoragePath();
    final file = _registryFile(basePath);
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];
    final list = jsonDecode(content) as List<dynamic>;
    return list
        .map((e) => OfflineRegion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeRegistry(List<OfflineRegion> regions) async {
    final basePath = await _ensureStoragePath();
    final file = _registryFile(basePath);
    final list = regions.map((r) => r.toJson()).toList();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(list));
  }

  @override
  Future<String> getStoragePath() async => _ensureStoragePath();

  @override
  Future<List<OfflineRegion>> getAll() async => _readRegistry();

  @override
  Future<OfflineRegion?> getById(String id) async {
    final list = await _readRegistry();
    try {
      return list.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> add(OfflineRegion region) async {
    final list = await _readRegistry();
    if (list.any((r) => r.id == region.id)) {
      throw StateError('Offline region ${region.id} already exists');
    }
    list.add(region);
    await _writeRegistry(list);
  }

  @override
  Future<void> delete(String id) async {
    final list = await _readRegistry();
    final filtered = list.where((r) => r.id != id).toList();
    if (filtered.length == list.length) return;
    final region = list.firstWhere((r) => r.id == id);
    final basePath = await _ensureStoragePath();
    final dir = Directory(path.join(basePath, region.relativePath));
    if (await dir.exists()) await dir.delete(recursive: true);
    await _writeRegistry(filtered);
  }

  @override
  Future<OfflineRegion?> getRegionForViewport(
    double north,
    double south,
    double east,
    double west,
  ) async {
    final list = await _readRegistry();
    for (final r in list) {
      if (r.intersectsBbox(north, south, east, west)) return r;
    }
    return null;
  }

  /// Full path to the region's tile directory (z/x/y.pbf under it).
  @override
  Future<String> getAbsolutePath(OfflineRegion region) async {
    final base = await _ensureStoragePath();
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
    throw UnsupportedError(
      'Use OfflineRegionsRepositoryRust for download (logic in Rust)',
    );
  }
}
