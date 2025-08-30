import 'package:nav_e/core/data/remote/geocoding_api_client.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/domain/repositories/geocoding_respository.dart';

class GeocodingRepositoryImpl implements IGeocodingRepository {
  final GeocodingApiClient api;
  GeocodingRepositoryImpl(this.api);

  @override
  Future<List<GeocodingResult>> search(String query, {int limit = 10}) async {
    final raw = await api.searchRaw(query, limit: limit);
    return raw.map((m) => GeocodingResult.fromJson(m)).toList();
  }
}
