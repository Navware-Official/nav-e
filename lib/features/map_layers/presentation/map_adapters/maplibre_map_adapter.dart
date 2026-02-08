import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/data/map_adapter.dart';
import 'package:nav_e/core/domain/entities/map_source.dart';
import 'package:nav_e/features/map_layers/models/marker_model.dart';
import 'package:nav_e/features/map_layers/models/polyline_model.dart';
import 'package:nav_e/features/map_layers/presentation/map_adapters/maplibre_widget.dart';

/// MapLibre implementation for all map types (vector and raster tiles)
///
/// This adapter uses MapLibre GL for rendering all map types, which provides:
/// - Vector tiles (MVT/PBF) for better performance and smaller data transfer
/// - Raster tiles (PNG/JPG) for satellite imagery and standard maps
/// - Custom style.json files for advanced styling
/// - Smooth rotation, tilt, and 3D capabilities
/// - Hardware-accelerated rendering
class MapLibreMapAdapter implements MapAdapter {
  MapLibreMapController? _controller;
  LatLng _currentCenter;
  double _currentZoom;

  MapLibreMapAdapter({LatLng? initialCenter, double? initialZoom})
    : _currentCenter = initialCenter ?? const LatLng(52.3791, 4.9),
      _currentZoom = initialZoom ?? 13.0;

  @override
  LatLng get currentCenter => _currentCenter;

  @override
  double get currentZoom => _currentZoom;

  @override
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
  }) {
    if (_controller == null) {
      _currentCenter = center;
      _currentZoom = zoom;
    }

    // Convert PolylineModel to MapLibrePolyline
    final mapLibrePolylines = polylines
        .asMap()
        .entries
        .map(
          (entry) => MapLibrePolyline(
            id: 'polyline_${entry.key}',
            points: entry.value.points,
            color: Color(entry.value.colorArgb),
            width: entry.value.strokeWidth,
          ),
        )
        .toList();

    // Convert MarkerModel to MapLibreMarker
    final mapLibreMarkers = markers
        .map(
          (m) => MapLibreMarker(id: m.id, position: m.position, icon: m.icon),
        )
        .toList();

    // Determine if source is a style (JSON URL or asset) or raster tile URL
    final url = source?.urlTemplate ?? '';
    final isStyleUrl =
        url.toLowerCase().contains('style.json') ||
        url.toLowerCase().startsWith('asset://');

    // Markers are drawn as native map circles (integrated into map layer).
    return MapLibreWidget(
      initialCenter: center,
      initialZoom: zoom,
      styleUrl: isStyleUrl ? source?.urlTemplate : null,
      rasterTileUrl: !isStyleUrl ? source?.urlTemplate : null,
      minZoom: source?.minZoom ?? 0,
      maxZoom: source?.maxZoom ?? 22,
      onMapCreated: (controller) {
        _controller = controller;
        onMapReady();
      },
      onCameraMove: (center, zoom) {
        _currentCenter = center;
        _currentZoom = zoom;
        onPositionChanged(center, zoom);
      },
      onMapTap: onMapTap,
      polylines: mapLibrePolylines,
      markers: mapLibreMarkers,
    );
  }

  @override
  void moveCamera(LatLng center, double zoom) {
    debugPrint('[MapLibreAdapter] moveCamera to $center $zoom');
    _currentCenter = center;
    _currentZoom = zoom;
    if (_controller != null) {
      _controller!.moveCamera(center, zoom);
    }
  }

  @override
  void resetBearing() {
    debugPrint('[MapLibreAdapter] resetBearing');
    if (_controller != null) {
      _controller!.resetBearing();
    }
  }

  @override
  void fitBounds({
    required List<LatLng> coordinates,
    required EdgeInsets padding,
    double? maxZoom,
  }) {
    if (coordinates.isEmpty || _controller == null) return;
    _controller!.fitBounds(coordinates, padding: padding);
  }

  @override
  bool supportsSource(MapSource source) {
    // MapLibre supports ALL map sources:
    // - Vector tiles (MVT/PBF format)
    // - Raster tiles (PNG/JPG - OSM, satellite, etc.)
    // - Custom style.json files
    return true;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
