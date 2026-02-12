import 'package:nav_e/core/domain/entities/offline_region.dart';

abstract class IOfflineRegionsRepository {
  /// Root directory for offline region files (e.g. MBTiles).
  Future<String> getStoragePath();

  Future<List<OfflineRegion>> getAll();

  Future<OfflineRegion?> getById(String id);

  Future<void> add(OfflineRegion region);

  Future<void> delete(String id);

  /// Region that contains the given point, or best match for viewport.
  Future<OfflineRegion?> getRegionForViewport(
    double north,
    double south,
    double east,
    double west,
  );

  /// Full path to the region's tile directory (z/x/y.pbf under it).
  Future<String> getAbsolutePath(OfflineRegion region);

  /// Download a region (Rust: fetch tiles, write dir, insert). Returns the new region or null on error.
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
  });
}
