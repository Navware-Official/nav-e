import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/domain/entities/saved_place.dart';

extension SavedPlaceToGeocoding on SavedPlace {
  GeocodingResult toGeocodingResult() {
    return GeocodingResult(
      placeId: int.tryParse(remoteId ?? '') ?? id ?? 0,
      licence: '',
      osmType: source,
      osmId: int.tryParse(remoteId ?? '') ?? 0,
      lat: lat,
      lon: lon,
      clazz: '',
      type: '',
      addressType: '',
      placeRank: 0,
      importance: 0.0,
      addresstype: '',
      name: name,
      displayName: address ?? name,
      boundingbox: const [],
      address: const {},
      id: '',
    );
  }
}
