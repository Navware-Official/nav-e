import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/domain/entities/saved_place.dart';

/// Extension methods on GeocodingResult to convert it to a [SavedPlace] object.
/// Includes an optional [typeId] parameter to categorize the saved place.
/// returns `SavedPlace`
extension GeocodingToSaved on GeocodingResult {
  SavedPlace toSavedPlace({int? typeId}) {
    return SavedPlace(
      id: null,
      typeId: typeId,
      source: osmId > 0 ? 'osm' : 'coords',
      remoteId: osmId > 0 ? osmId.toString() : id,
      name: (name.isNotEmpty ? name : displayName),
      address: displayName,
      lat: lat,
      lon: lon,
      createdAt: DateTime.now(),
    );
  }
}
