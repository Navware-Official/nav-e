import 'package:nav_e/core/domain/entities/geocoding_result.dart';

/// Extension methods on GeocodingResult to map it to path parameters for navigation.
/// parameters:
/// - [lat]: Latitude of the location.
/// - [lon]: Longitude of the location.
/// - [label]: Display name or label for the location.
/// - [placeId]: Optional place ID for the location.
/// returns `GeocodingResult`
extension PreviewParamsMapper on GeocodingResult {
  static GeocodingResult toPathParams({
    required double lat,
    required double lon,
    required String label,
    String? placeId,
  }) {
    return GeocodingResult(
      placeId: placeId != null ? int.tryParse(placeId) ?? 0 : 0,
      licence: '',
      osmType: '',
      osmId: 0,
      lat: lat,
      lon: lon,
      clazz: '',
      type: '',
      addressType: '',
      placeRank: 0,
      importance: 0.0,
      name: label,
      displayName: label,
      boundingbox: [],
      address: null,
      id: 'preview',
    );
  }
}
