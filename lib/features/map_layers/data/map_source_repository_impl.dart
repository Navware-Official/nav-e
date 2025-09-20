import 'package:nav_e/core/data/local/database_helper.dart';
import 'package:nav_e/core/domain/entities/map_source.dart';
import 'package:nav_e/core/domain/repositories/map_source_repository.dart';

class MapSourceRepositoryImpl implements IMapSourceRepository {
  final DatabaseHelper
  db; //TODO: Make chosen source persist using db or shared preference
  String _currentId = 'osm';

  MapSourceRepositoryImpl(this.db);

  static const _sources = <MapSource>[
    MapSource(
      id: 'osm',
      name: 'OpenStreetMap',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      attribution: '© OpenStreetMap contributors',
      maxZoom: 19,
      headers: {'User-Agent': 'nav-e/1.0 (info@navware.org)'},
    ),
    // Add other sources below using the MapSourceObject.
  ];

  @override
  Future<MapSource> getCurrent() async {
    return _sources.firstWhere((s) => s.id == _currentId);
  }

  @override
  Future<List<MapSource>> getAll() async => _sources;

  @override
  Future<void> setCurrent(String id) async {
    _currentId = id;
  }
}
