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
  if (s.subdomains != null && s.subdomains!.isNotEmpty) {
    final sd = s.subdomains![subdomainIndex % s.subdomains!.length];
    url = url.replaceAll('{s}', sd);
  }
  return url
      .replaceAll('{z}', '$z')
      .replaceAll('{x}', '$x')
      .replaceAll('{y}', '$y');
}
