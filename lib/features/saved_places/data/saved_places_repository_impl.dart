import 'package:nav_e/core/domain/entities/saved_place.dart';
import 'package:nav_e/core/domain/repositories/saved_places_repository.dart';
import 'package:sqflite/sqflite.dart';

class SavedPlacesRepositoryImpl implements ISavedPlacesRepository {
  final Database db;

  SavedPlacesRepositoryImpl(this.db);

  @override
  Future<List<SavedPlace>> getAll() async {
    final result = await db.query('saved_places', orderBy: 'created_at DESC');
    return result
        .map(
          (row) => SavedPlace(
            id: row['id'] as int,
            typeId: row['type_id'] as int?,
            source: row['source'] as String,
            remoteId: row['remote_id'] as String?,
            name: row['name'] as String,
            address: row['address'] as String?,
            lat: row['lat'] as double,
            lon: row['lon'] as double,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row['created_at'] as int,
            ),
          ),
        )
        .toList();
  }

  @override
  Future<SavedPlace?> getById(int id) async {
    final result = await db.query(
      'saved_places',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    final row = result.first;
    return SavedPlace(
      id: row['id'] as int,
      typeId: row['type_id'] as int?,
      source: row['source'] as String,
      remoteId: row['remote_id'] as String?,
      name: row['name'] as String,
      address: row['address'] as String?,
      lat: row['lat'] as double,
      lon: row['lon'] as double,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }

  @override
  Future<int> insert(SavedPlace place) {
    return db.insert('saved_places', {
      'type_id': place.typeId,
      'source': place.source,
      'remote_id': place.remoteId,
      'name': place.name,
      'address': place.address,
      'lat': place.lat,
      'lon': place.lon,
      'created_at': place.createdAt.millisecondsSinceEpoch,
    });
  }

  @override
  Future<int> delete(int id) {
    return db.delete('saved_places', where: 'id = ?', whereArgs: [id]);
  }
}
