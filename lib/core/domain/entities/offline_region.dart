/// Represents a downloaded offline map region.
///
/// Stored as MBTiles (or tile directory) in app documents;
/// registry holds id, name, bbox, path, zoom range, size.
class OfflineRegion {
  final String id;
  final String name;
  final double north;
  final double south;
  final double east;
  final double west;
  final int minZoom;
  final int maxZoom;

  /// Relative path from offline storage root (e.g. "region_abc.mbtiles").
  final String relativePath;

  /// Approximate size in bytes.
  final int sizeBytes;
  final DateTime createdAt;

  const OfflineRegion({
    required this.id,
    required this.name,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
    required this.minZoom,
    required this.maxZoom,
    required this.relativePath,
    required this.sizeBytes,
    required this.createdAt,
  });

  /// Bounding box as (north, south, east, west).
  (double, double, double, double) get bbox => (north, south, east, west);

  /// Whether [lat, lon] is inside this region's bbox.
  bool containsPoint(double lat, double lon) {
    return lat <= north && lat >= south && lon >= west && lon <= east;
  }

  /// Whether the given viewport bbox (n,s,e,w) intersects this region.
  bool intersectsBbox(double n, double s, double e, double w) {
    return !(n < south || s > north || e < west || w > east);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'north': north,
      'south': south,
      'east': east,
      'west': west,
      'minZoom': minZoom,
      'maxZoom': maxZoom,
      'relativePath': relativePath,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory OfflineRegion.fromJson(Map<String, dynamic> json) {
    return OfflineRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      north: (json['north'] as num).toDouble(),
      south: (json['south'] as num).toDouble(),
      east: (json['east'] as num).toDouble(),
      west: (json['west'] as num).toDouble(),
      minZoom: json['minZoom'] as int,
      maxZoom: json['maxZoom'] as int,
      relativePath: json['relativePath'] as String,
      sizeBytes: json['sizeBytes'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }
}
