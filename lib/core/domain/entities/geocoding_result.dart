import 'package:latlong2/latlong.dart';

class GeocodingResult {
  final int placeId;
  final String licence;
  final String osmType;
  final int osmId;
  final double lat;
  final double lon;
  final String clazz;
  final String type;
  final String addressType;
  final int placeRank;
  final double importance;
  final String name;
  final String displayName;
  final List<String> boundingbox;
  final Map<String, dynamic>? address;

  final String? id;

  GeocodingResult({
    required this.placeId,
    required this.licence,
    required this.osmType,
    required this.osmId,
    required this.lat,
    required this.lon,
    required this.clazz,
    required this.type,
    required this.addressType,
    required this.placeRank,
    required this.importance,
    required this.name,
    required this.displayName,
    required this.boundingbox,
    this.address,
    this.id,
  });

  LatLng get position => LatLng(lat, lon);

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      placeId: json['place_id'] as int,
      licence: json['licence'] as String? ?? '',
      osmType: json['osm_type'] as String? ?? '',
      osmId: json['osm_id'] as int,
      lat: json['lat'] is num
          ? (json['lat'] as num).toDouble()
          : double.parse(json['lat'].toString()),
      lon: json['lon'] is num
          ? (json['lon'] as num).toDouble()
          : double.parse(json['lon'].toString()),
      clazz: json['class'] as String? ?? '',
      type: json['type'] as String? ?? '',
      addressType:
          json['addresstype'] as String? ??
          json['addressType'] as String? ??
          '',
      placeRank: json['place_rank'] as int? ?? 0,
      importance: json['importance'] is num
          ? (json['importance'] as num).toDouble()
          : double.tryParse(json['importance']?.toString() ?? '') ?? 0,
      name:
          (json['name'] as String?) ?? (json['display_name'] as String? ?? ''),
      displayName:
          (json['display_name'] as String?) ?? (json['name'] as String? ?? ''),
      boundingbox:
          (json['boundingbox'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      address: json['address'] as Map<String, dynamic>?,
      id: null,
    );
  }

  factory GeocodingResult.minimal({
    required double lat,
    required double lon,
    required String label,
    String? id,
  }) {
    return GeocodingResult(
      placeId: -1,
      licence: '',
      osmType: 'coords',
      osmId: -1,
      lat: lat,
      lon: lon,
      clazz: 'place',
      type: 'coords',
      addressType: '',
      placeRank: 0,
      importance: 0,
      name: label,
      displayName: label,
      boundingbox: const [],
      address: null,
      id: id,
    );
  }

  Map<String, String> toPathParams() {
    final params = <String, String>{
      'lat': lat.toStringAsFixed(6),
      'lon': lon.toStringAsFixed(6),
      'label': displayName,
    };
    if (id != null && id!.isNotEmpty) params['placeId'] = id!;
    return params;
  }

  static GeocodingResult? fromPathParams(Map<String, String> params) {
    final lat = double.tryParse(params['lat'] ?? '');
    final lon = double.tryParse(params['lon'] ?? '');
    if (lat == null || lon == null) return null;
    final label = params['label'] ?? 'Selected location';
    return GeocodingResult.minimal(
      lat: lat,
      lon: lon,
      label: label,
      id: params['placeId'],
    );
  }
}
