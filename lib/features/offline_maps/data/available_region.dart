/// One entry from the nav-dsp `GET /v1/tiles/regions` catalog.
class AvailableRegion {
  const AvailableRegion({
    required this.regionId,
    required this.name,
    required this.sizeMb,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  final String regionId;
  final String name;
  final int sizeMb;
  final double north;
  final double south;
  final double east;
  final double west;

  factory AvailableRegion.fromJson(Map<String, dynamic> json) {
    final bounds = json['bounds'] as Map<String, dynamic>;
    return AvailableRegion(
      regionId: json['region_id'] as String,
      name: json['name'] as String,
      sizeMb: (json['size_mb'] as num).toInt(),
      north: (bounds['north'] as num).toDouble(),
      south: (bounds['south'] as num).toDouble(),
      east: (bounds['east'] as num).toDouble(),
      west: (bounds['west'] as num).toDouble(),
    );
  }
}
