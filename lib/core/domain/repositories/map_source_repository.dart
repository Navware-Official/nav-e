import 'package:nav_e/core/domain/entities/map_source.dart';

abstract class IMapSourceRepository {
  Future<MapSource> getCurrent();
  Future<List<MapSource>> getAll();
  Future<void> setCurrent(String id);
}
