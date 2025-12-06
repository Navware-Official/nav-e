import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';
import 'package:nav_e/bridge/geocode.dart' as geocode;

/// FRB-backed geocoding repository using generated typed bindings.
class GeocodingRepositoryFrbTypedImpl implements IGeocodingRepository {
  GeocodingRepositoryFrbTypedImpl();

  @override
  Future<List<GeocodingResult>> search(String query, {int limit = 10}) async {
    // Use generated typed binding which returns typed objects
    final list = await geocode.searchTyped(query: query, limit: limit);
    return list.map((result) => GeocodingResult(
      placeId: result.placeId,
      licence: result.licence ?? '',
      osmType: result.osmType ?? '',
      osmId: result.osmId ?? 0,
      lat: double.tryParse(result.lat) ?? 0.0,
      lon: double.tryParse(result.lon) ?? 0.0,
      clazz: result.classField ?? '',
      type: result.typeField ?? '',
      addressType: '', // Not provided by Rust side
      placeRank: 0, // Not provided by Rust side
      importance: result.importance ?? 0.0,
      name: result.displayName ?? '',
      displayName: result.displayName ?? '',
      boundingbox: result.boundingbox ?? [],
      address: result.address?.map((k, v) => MapEntry(k, v as dynamic)),
    )).toList();
  }
}
