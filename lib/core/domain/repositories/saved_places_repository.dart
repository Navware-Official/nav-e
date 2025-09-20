import 'package:nav_e/core/domain/entities/saved_place.dart';

abstract class ISavedPlacesRepository {
  Future<List<SavedPlace>> getAll();
  Future<SavedPlace?> getById(int id);
  Future<int> insert(SavedPlace place);
  Future<int> delete(int id);
}
