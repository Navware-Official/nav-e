import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/data/map_adapter.dart';
import 'package:nav_e/core/domain/entities/map_source.dart';
import 'package:nav_e/features/map_layers/presentation/map_adapters/legacy_map_adapter.dart';
import 'package:nav_e/features/map_layers/presentation/map_adapters/maplibre_map_adapter.dart';

/// Feature flag for enabling MapLibre vector tiles
/// Set to true to use MapLibre, false to use legacy flutter_map
const bool _useMapLibre = false;

/// Factory for creating the appropriate map adapter based on configuration
class MapAdapterFactory {
  /// Create a map adapter based on the feature flag and map source
  /// 
  /// If [useMapLibre] is true and the source supports vector tiles,
  /// returns a MapLibreMapAdapter. Otherwise returns a LegacyMapAdapter.
  /// 
  /// The [source] parameter is used to determine compatibility.
  static MapAdapter create({
    MapSource? source,
    LatLng? initialCenter,
    double? initialZoom,
    bool? useMapLibre,
  }) {
    final shouldUseMapLibre = useMapLibre ?? _useMapLibre;

    // If MapLibre is enabled and the source supports it, use MapLibre
    if (shouldUseMapLibre && source != null) {
      final mapLibreAdapter = MapLibreMapAdapter(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
      );

      if (mapLibreAdapter.supportsSource(source)) {
        return mapLibreAdapter;
      }
    }

    // Fall back to legacy adapter for raster tiles
    return LegacyMapAdapter();
  }

  /// Check if MapLibre is enabled via feature flag
  static bool get isMapLibreEnabled => _useMapLibre;
}
