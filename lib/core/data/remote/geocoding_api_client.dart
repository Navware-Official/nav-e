import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingApiClient {
  final http.Client _http;
  GeocodingApiClient(this._http);

  Future<List<Map<String, dynamic>>> searchRaw(
    String query, {
    int limit = 10,
  }) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=$limit',
    );

    final response = await _http.get(
      url,
      headers: {'User-Agent': 'nav-e-app/1.0 (info@navware.org)'},
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch geocoding data: ${response.statusCode}');
    }
  }
}
