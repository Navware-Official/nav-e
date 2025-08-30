class MapSource {
  final String id;
  final String name;
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
