class SavedPlace {
  final int? id;
  final int? typeId;
  final String source;
  final String? remoteId;
  final String name;
  final String? address;
  final double lat;
  final double lon;
  final DateTime createdAt;

  SavedPlace({
    this.id,
    this.typeId,
    required this.source,
    this.remoteId,
    required this.name,
    this.address,
    required this.lat,
    required this.lon,
    required this.createdAt,
  });
}
