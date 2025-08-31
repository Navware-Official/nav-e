import 'package:nav_e/core/domain/entities/geocoding_result.dart';

abstract class IGeocodingRepository {
  Future<List<GeocodingResult>> search(String query, {int limit = 10});
}
