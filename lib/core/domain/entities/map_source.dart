// ignore_for_file: unnecessary_null_comparison

import 'dart:math';

class MapSource {
  final String id;
  final String name;
  final String? description;
  final String urlTemplate;
  final List<String> subdomains;
  final int minZoom;
  final int maxZoom;
  final String? attribution;
  final Map<String, String>? headers;
  final Map<String, String>? queryParams;
  final bool isWms;

  const MapSource({
    required this.id,
    required this.name,
    this.description,
    required this.urlTemplate,
    this.subdomains = const [],
    this.minZoom = 0,
    this.maxZoom = 19,
    this.attribution,
    this.headers,
    this.queryParams,
    this.isWms = false,
  });

  factory MapSource.fromJson(Map<String, dynamic> json) {
    return MapSource(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      urlTemplate: json['urlTemplate'] as String,
      subdomains: json['subdomains'] != null
          ? List<String>.from(json['subdomains'] as List)
          : const [],
      minZoom: json['minZoom'] as int? ?? 0,
      maxZoom: json['maxZoom'] as int? ?? 19,
      attribution: json['attribution'] as String?,
      headers: json['headers'] != null
          ? Map<String, String>.from(json['headers'] as Map)
          : null,
      queryParams: json['queryParams'] != null
          ? Map<String, String>.from(json['queryParams'] as Map)
          : null,
      isWms: json['isWms'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'urlTemplate': urlTemplate,
      if (subdomains.isNotEmpty) 'subdomains': subdomains,
      'minZoom': minZoom,
      'maxZoom': maxZoom,
      if (attribution != null) 'attribution': attribution,
      if (headers != null) 'headers': headers,
      if (queryParams != null) 'queryParams': queryParams,
      if (isWms) 'isWms': isWms,
    };
  }
}

({int x, int y}) tileXY(double lat, double lon, int z) {
  final latRad = lat * pi / 180.0;
  final n = pow(2.0, z).toDouble();
  final x = ((lon + 180.0) / 360.0 * n).floor();
  final y = ((1 - (log(tan(latRad) + 1 / cos(latRad)) / pi)) / 2 * n).floor();
  return (x: x, y: y);
}

String previewUrlFor(
  MapSource s, {
  required int z,
  required int x,
  required int y,
  int subdomainIndex = 0,
}) {
  var url = s.urlTemplate;
  if (s.subdomains != null && s.subdomains.isNotEmpty) {
    final sd = s.subdomains[subdomainIndex % s.subdomains.length];
    url = url.replaceAll('{s}', sd);
  }
  return url
      .replaceAll('{z}', '$z')
      .replaceAll('{x}', '$x')
      .replaceAll('{y}', '$y');
}
