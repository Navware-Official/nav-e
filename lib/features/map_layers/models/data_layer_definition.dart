/// Defines a data overlay layer (e.g. parking) for the map.
/// [geojsonAssetPath] is the asset path (e.g. 'assets/data/parking.geojson').
/// [geometryType] determines which MapLibre layer type to use: fill, circle, or line.
class DataLayerDefinition {
  final String id;
  final String name;
  final String geojsonAssetPath;
  final DataLayerGeometryType geometryType;

  const DataLayerDefinition({
    required this.id,
    required this.name,
    required this.geojsonAssetPath,
    this.geometryType = DataLayerGeometryType.fill,
  });
}

enum DataLayerGeometryType {
  fill,
  circle,
  line,
}
