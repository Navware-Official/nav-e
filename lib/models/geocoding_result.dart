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
  final String addresstype;
  final String name;
  final String displayName;
  final List<String> boundingbox;
  final Map<String, dynamic>? address;

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
    required this.addresstype,
    required this.name,
    required this.displayName,
    required this.boundingbox,
    this.address,
  });

  LatLng get position => LatLng(lat, lon);

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      placeId: json['place_id'],
      licence: json['licence'],
      osmType: json['osm_type'],
      osmId: json['osm_id'],
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
      clazz: json['class'],
      type: json['type'],
      addressType: json['addresstype'],
      placeRank: json['place_rank'],
      importance: (json['importance'] is double)
          ? json['importance']
          : double.parse(json['importance'].toString()),
      addresstype: json['addresstype'],
      name: json['name'],
      displayName: json['display_name'],
      boundingbox: List<String>.from(json['boundingbox']),
      address: json['address'],
    );
  }
}