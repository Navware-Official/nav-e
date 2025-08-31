import 'package:nav_e/core/domain/entities/map_source.dart';
import 'package:nav_e/core/domain/repositories/map_source_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapSourceRepositoryImpl implements IMapSourceRepository {
  static const List<MapSource> _registry = [
    MapSource(
      id: 'osm',
      name: 'OpenStreetMap',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      maxZoom: 19,
      headers: {'User-Agent': 'nav-e/1.0 (info@navware.org)'},
    ),
    MapSource(
      id: 'satellite',
      name: 'Esri Satellite',
      urlTemplate:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      maxZoom: 19,
      attribution:
          'Tiles © Esri — Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
      headers: {'User-Agent': 'nav-e/1.0'},
    ),
  ];

  static const _prefsKey = 'selected_map_source_id';
  Object _currentId = 'osm';

  MapSourceRepositoryImpl() {
    _loadCurrentId();
  }

  Future<void> _loadCurrentId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefsKey);
    if (savedId != null && _registry.any((s) => s.id == savedId)) {
      _currentId = savedId;
    }
  }

  Future<void> _saveCurrentId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id);
  }

  @override
  Future<MapSource> getCurrent() async =>
      _registry.firstWhere((s) => s.id == _currentId);

  @override
  Future<List<MapSource>> getAll() async => _registry;

  @override
  Future<void> setCurrent(String id) async {
    if (_registry.any((s) => s.id == id)) {
      _currentId = id;
      await _saveCurrentId(id);
    }
  }
}
