import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nav_e/core/models/geocoding_result.dart';

class GeocodingService {
  Future<List<GeocodingResult>> search(String query) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=10',
    );

    final response = await http.get(url, headers: {
      'User-Agent': 'nav-e-app/1.0 (info@navware.org)',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<GeocodingResult>.from(data.map((item) => GeocodingResult.fromJson(item)));
    } else {
      throw Exception('Failed to fetch location data');
    }
  }
}