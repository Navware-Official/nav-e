import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingResult {
  final String displayName;
  final LatLng position;
  final String? name;
  final String? type;
  final Map<String, dynamic>? address;

  GeocodingResult({
    required this.displayName,
    required this.position,
    this.name,
    this.type,
    this.address,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      displayName: json['display_name'],
      position: LatLng(
        double.parse(json['lat']),
        double.parse(json['lon']),
      ),
      name: json['name'],
      type: json['type'],
      address: json['address'],
    );
  }
}

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
      return List<GeocodingResult>.from(data.map((item) {
        return GeocodingResult(
          displayName: item['display_name'],
          position: LatLng(
            double.parse(item['lat']),
            double.parse(item['lon']),
          ),
        );
      }));
    } else {
      //TODO: show alertDialog with error message

      throw Exception('Failed to fetch location data');
    }
  }
}
