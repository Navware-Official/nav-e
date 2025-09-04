import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/domain/entities/saved_place.dart';

extension GeocodingResultMapper on GeocodingResult {
  SavedPlace toSavedPlace({int? typeId}) {
    return SavedPlace(
      typeId: typeId,
      source: 'osm',
      remoteId: osmId.toString(),
      name: name.isNotEmpty ? name : displayName,
      address: displayName,
      lat: lat,
      lon: lon,
      createdAt: DateTime.now(),
    );
  }
}
