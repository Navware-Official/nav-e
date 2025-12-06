import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/data/map_adapter.dart';
import 'package:nav_e/core/domain/entities/map_source.dart';
import 'package:nav_e/features/map_layers/models/polyline_model.dart';
import 'package:nav_e/features/map_layers/presentation/map_adapters/maplibre_widget.dart';

/// MapLibre implementation for vector tiles
/// 
/// This adapter uses MapLibre GL for rendering vector tiles, which provides:
/// - Better performance on low-end devices
/// - Smaller data transfer (vector vs raster)
/// - Smooth rotation and tilt
/// - Better typography and styling
class MapLibreMapAdapter implements MapAdapter {
  MapLibreController? _controller;
  LatLng _currentCenter;
  double _currentZoom;

  MapLibreMapAdapter({
    LatLng? initialCenter,
    double? initialZoom,
  })  : _currentCenter = initialCenter ?? const LatLng(52.3791, 4.9),
        _currentZoom = initialZoom ?? 13.0;

  @override
  Widget buildMap({
    required MapSource? source,
    required LatLng center,
    required double zoom,
    required List<Widget> markers,
    required List<PolylineModel> polylines,
    required VoidCallback onMapReady,
    required void Function(LatLng center, double zoom) onPositionChanged,
    required void Function(bool hasGesture) onUserGesture,
    required void Function(LatLng)? onMapTap,
  }) {
    _currentCenter = center;
    _currentZoom = zoom;

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

    // Convert markers (if needed - currently markers are widgets)
    // In a real implementation, you'd convert these to MapLibre markers
    final mapLibreMarkers = <MapLibreMarker>[];

    return MapLibreWidget(
      initialCenter: center,
      initialZoom: zoom,
      styleUrl: source?.urlTemplate,
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
    _currentCenter = center;
    _currentZoom = zoom;
    _controller?.moveCamera(center, zoom);
  }

  @override
  void fitBounds({
    required List<LatLng> coordinates,
    required EdgeInsets padding,
    double? maxZoom,
  }) {
    if (coordinates.isEmpty) return;
    _controller?.fitBounds(coordinates, padding: padding);
  }

  @override
  LatLng get currentCenter => _currentCenter;

  @override
  double get currentZoom => _currentZoom;

  @override
  bool supportsSource(MapSource source) {
    // MapLibre supports vector tiles (MVT/PBF format)
    // Also supports raster tiles as a fallback
    // Typically identified by .pbf extension or mbtiles
    final url = source.urlTemplate.toLowerCase();
    return url.contains('.pbf') ||
        url.contains('vector') ||
        url.contains('mbtiles') ||
        url.contains('style.json');
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
