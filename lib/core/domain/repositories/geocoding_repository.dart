import 'package:nav_e/core/domain/entities/geocoding_result.dart';

abstract class IGeocodingRepository {
  Future<List<GeocodingResult>> search(String query, {int limit = 10});

  /// Reverse geocode coordinates to a displayable location result
  Future<GeocodingResult> reverseGeocode({
    required double lat,
    required double lon,
  });
}
