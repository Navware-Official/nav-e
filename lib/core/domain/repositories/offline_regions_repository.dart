import 'package:nav_e/core/domain/entities/offline_region.dart';
import 'package:nav_e/features/offline_maps/data/available_region.dart';

abstract class IOfflineRegionsRepository {
  /// Root directory holding `.pmtiles` archives.
  Future<String> getStoragePath();

  Future<List<OfflineRegion>> getAll();

  Future<OfflineRegion?> getById(String id);

  Future<void> delete(String id);

  /// Region that contains the given point, or best match for viewport.
  Future<OfflineRegion?> getRegionForViewport(
    double north,
    double south,
    double east,
    double west,
  );

  /// Full path to the region's PMTiles archive on disk.
  Future<String> getAbsolutePath(OfflineRegion region);

  /// Catalog of regions advertised by the nav-dsp gateway.
  Future<List<AvailableRegion>> listAvailableRegions();

  /// Download a region's PMTiles archive from the gateway and register it locally.
  /// Returns the new region or `null` on error.
  Future<OfflineRegion?> downloadRegion({required String regionId});
}
