import 'dart:convert';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';
import 'package:nav_e/bridge/lib.dart' as rust;

/// FRB-backed geocoding repository using the new DDD/CQRS API.
class GeocodingRepositoryFrbTypedImpl implements IGeocodingRepository {
  GeocodingRepositoryFrbTypedImpl();

  @override
  Future<List<GeocodingResult>> search(String query, {int limit = 10}) async {
    // Use the new clean API that returns JSON with rich geocoding data
    
    try {
      final json = await rust.geocodeSearch(query: query, limit: limit);
      
      final List<dynamic> results = jsonDecode(json);
      
      if (results.isEmpty) {
        return [];
      }
    
    return results.asMap().entries.map((entry) {
      final index = entry.key;
      final map = entry.value as Map<String, dynamic>;
      
      // The Rust API returns GeocodingResultDto with:
      // - latitude, longitude, display_name (required)
      // - name, city, country, osm_type, osm_id (optional)
      final lat = (map['latitude'] as num?)?.toDouble() ?? 0.0;
      final lon = (map['longitude'] as num?)?.toDouble() ?? 0.0;
      final displayName = map['display_name'] as String? ?? '';
      final name = map['name'] as String? ?? displayName.split(',').first.trim();
      final osmType = map['osm_type'] as String? ?? '';
      final osmId = map['osm_id'] as int? ?? 0;
      
      return GeocodingResult(
        placeId: index, // Use index as placeholder ID
        licence: '',
        osmType: osmType,
        osmId: osmId,
        lat: lat,
        lon: lon,
        clazz: '',
        type: '',
        addressType: '',
        placeRank: 0,
        importance: 0.0,
        name: name,
        displayName: displayName,
        boundingbox: [],
        address: null,
      );
    }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
