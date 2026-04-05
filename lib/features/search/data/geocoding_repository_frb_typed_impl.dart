import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';
import 'package:nav_e/bridge/lib.dart' as rust;

/// FRB-backed geocoding repository using the new DDD/CQRS API.
class GeocodingRepositoryFrbTypedImpl implements IGeocodingRepository {
  GeocodingRepositoryFrbTypedImpl();

  @override
  Future<List<GeocodingResult>> search(String query, {int limit = 10}) async {
    final results = await rust.geocodeSearch(query: query, limit: limit);

    return results.asMap().entries.map((entry) {
      final index = entry.key;
      final r = entry.value;
      final name = r.name ?? r.displayName.split(',').first.trim();
      return GeocodingResult(
        placeId: index,
        licence: '',
        osmType: r.osmType ?? '',
        osmId: r.osmId?.toInt() ?? 0,
        lat: r.latitude,
        lon: r.longitude,
        clazz: '',
        type: '',
        addressType: '',
        placeRank: 0,
        importance: 0.0,
        name: name,
        displayName: r.displayName,
        boundingbox: [],
        address: null,
      );
    }).toList();
  }

  @override
  Future<GeocodingResult> reverseGeocode({
    required double lat,
    required double lon,
  }) async {
    final label = await rust.reverseGeocode(latitude: lat, longitude: lon);

    final resolvedLabel = label.trim().isEmpty
        ? '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}'
        : label;

    return GeocodingResult.minimal(lat: lat, lon: lon, label: resolvedLabel);
  }
}
