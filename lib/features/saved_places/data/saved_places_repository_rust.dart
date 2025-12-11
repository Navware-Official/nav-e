import 'dart:convert';
import 'package:nav_e/core/domain/entities/saved_place.dart';
import 'package:nav_e/core/domain/repositories/saved_places_repository.dart';
import 'package:nav_e/bridge/lib.dart' as rust;

/// Rust-backed saved places repository
/// All persistence logic is handled in Rust, this is a thin wrapper
class SavedPlacesRepositoryRust implements ISavedPlacesRepository {
  @override
  Future<List<SavedPlace>> getAll() async {
    final json = rust.getAllSavedPlaces();
    final List<dynamic> data = jsonDecode(json);
    
    return data.map((item) => _fromRustJson(item)).toList();
  }

  @override
  Future<SavedPlace?> getById(int id) async {
    final json = rust.getSavedPlaceById(id: id);
    if (json == 'null') return null;
    
    final data = jsonDecode(json);
    return _fromRustJson(data);
  }

  @override
  Future<int> insert(SavedPlace place) async {
    try {
      print('[DART SAVE] Attempting to save place: ${place.name}');
      final id = rust.savePlace(
        name: place.name,
        address: place.address,
        lat: place.lat,
        lon: place.lon,
        source: place.source,
        typeId: place.typeId,
        remoteId: place.remoteId,
      );
      print('[DART SAVE] Successfully saved with ID: $id');
      return id;
    } catch (e, stackTrace) {
      print('[DART SAVE ERROR] Failed to save place: $e');
      print('[DART SAVE ERROR] Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<int> delete(int id) async {
    rust.deleteSavedPlace(id: id);
    return 1; // Rust doesn't return affected rows, assume success
  }

  SavedPlace _fromRustJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: json['id'] as int?,
      typeId: json['type_id'] as int?,
      source: json['source'] as String,
      remoteId: json['remote_id'] as String?,
      name: json['name'] as String,
      address: json['address'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
    );
  }
}
