import 'package:nav_e/features/map_layers/models/data_layer_definition.dart';

/// Returns the list of available data layer definitions (e.g. parking overlay).
/// GeoJSON is loaded from assets at runtime when a layer is enabled.
List<DataLayerDefinition> getDataLayerDefinitions() {
  return const [
    DataLayerDefinition(
      id: 'parking',
      name: 'Parking overlays',
      geojsonAssetPath: 'assets/data/parking.geojson',
      geometryType: DataLayerGeometryType.fill,
    ),
  ];
}
