import 'package:nav_e/core/domain/entities/map_source.dart';
import 'package:nav_e/core/domain/entities/offline_region.dart';
import 'package:nav_e/core/domain/repositories/map_source_repository.dart';
import 'package:nav_e/core/domain/repositories/offline_regions_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _prefsKey = 'selected_map_source_id';

/// Merges base map sources with offline regions. Offline regions appear as
/// MapSources with id "offline_region_<id>" and urlTemplate "offline://<id>".
class CompositeMapSourceRepository implements IMapSourceRepository {
  CompositeMapSourceRepository(this._base, this._offlineRegions);

  final IMapSourceRepository _base;
  final IOfflineRegionsRepository _offlineRegions;

  @override
  Future<MapSource> getCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefsKey);
    if (id != null && id.startsWith('offline_region_')) {
      final regionId = id.replaceFirst('offline_region_', '');
      final region = await _offlineRegions.getById(regionId);
      if (region != null) return _regionToMapSource(region);
    }
    return _base.getCurrent();
  }

  @override
  Future<List<MapSource>> getAll() async {
    final base = await _base.getAll();
    final regions = await _offlineRegions.getAll();
    final offlineSources = regions.map((r) => _regionToMapSource(r)).toList();
    return [...base, ...offlineSources];
  }

  @override
  Future<void> setCurrent(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id);
    if (!id.startsWith('offline_region_')) {
      await _base.setCurrent(id);
    }
  }

  MapSource _regionToMapSource(OfflineRegion r) {
    return MapSource(
      id: 'offline_region_${r.id}',
      name: 'Offline: ${r.name}',
      urlTemplate: 'offline://${r.id}',
      minZoom: r.minZoom,
      maxZoom: r.maxZoom,
      attribution: 'Offline region',
    );
  }
}
