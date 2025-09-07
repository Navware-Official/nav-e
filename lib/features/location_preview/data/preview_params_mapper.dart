import 'package:nav_e/core/domain/entities/geocoding_result.dart';

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
      addresstype: '',
      name: label,
      displayName: label,
      boundingbox: [],
      address: null,
      id: 'preview',
    );
  }
}
