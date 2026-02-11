import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/domain/entities/map_source.dart';
import 'package:nav_e/features/map_layers/models/marker_model.dart';
import 'package:nav_e/features/map_layers/models/polyline_model.dart';

/// Abstract interface for map rendering implementations (OSM/MapLibre/etc).
/// Allows swapping between flutter_map (raster tiles) and MapLibre (vector tiles)
/// without changing the business logic in MapBloc.
abstract class MapAdapter {
  /// Build the map widget with the current state
  Widget buildMap({
    required MapSource? source,
    required LatLng center,
    required double zoom,
    required List<MarkerModel> markers,
    required List<PolylineModel> polylines,
    required VoidCallback onMapReady,
    required void Function(LatLng center, double zoom) onPositionChanged,
    required void Function(bool hasGesture) onUserGesture,
    required void Function(LatLng)? onMapTap,
  });

  /// Move the map camera to a specific location
  void moveCamera(
    LatLng center,
    double zoom, {
    double? tilt,
    double? bearing,
  });

  /// Reset the map bearing (rotation) to north
  void resetBearing();

  /// Fit the map to show all coordinates with padding
  void fitBounds({
    required List<LatLng> coordinates,
    required EdgeInsets padding,
    double? maxZoom,
  });

  /// Get the current camera position
  LatLng get currentCenter;
  double get currentZoom;
  double get currentTilt;
  double get currentBearing;

  /// Check if the adapter supports a given map source
  bool supportsSource(MapSource source);

  /// Dispose any resources
  void dispose();
}
