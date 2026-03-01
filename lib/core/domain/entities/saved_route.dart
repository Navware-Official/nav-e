class SavedRoute {
  final int? id;
  final String name;
  final String routeJson;
  final String source; // e.g. 'gpx', 'plan'
  final DateTime createdAt;

  SavedRoute({
    this.id,
    required this.name,
    required this.routeJson,
    required this.source,
    required this.createdAt,
  });
}
