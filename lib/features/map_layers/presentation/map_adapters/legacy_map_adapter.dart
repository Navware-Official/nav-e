import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/data/map_adapter.dart';
import 'package:nav_e/core/domain/entities/map_source.dart';
import 'package:nav_e/features/map_layers/models/polyline_model.dart';

/// Legacy implementation using flutter_map for raster/OSM tiles
class LegacyMapAdapter implements MapAdapter {
  final MapController _controller;

  LegacyMapAdapter() : _controller = MapController();

  MapController get controller => _controller;

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
    return RepaintBoundary(
      child: FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          onTap: (tapPos, latlng) {
            onMapTap?.call(latlng);
          },
          onMapReady: onMapReady,
          onPositionChanged: (pos, hasGesture) {
            if (hasGesture) {
              onUserGesture(hasGesture);
            }
            final c = pos.center;
            final z = pos.zoom;
            onPositionChanged(c, z);
          },
        ),
        children: [
          if (source != null)
            TileLayer(
              urlTemplate: _withQueryParams(
                source.urlTemplate,
                source.queryParams,
              ),
              subdomains: source.subdomains,
              minZoom: source.minZoom.toDouble(),
              maxZoom: source.maxZoom.toDouble(),
              userAgentPackageName: 'nav_e.navware',
              additionalOptions: Map<String, String>.from(
                source.queryParams ?? const {},
              ),
              tileProvider: NetworkTileProvider(
                headers: Map<String, String>.from(source.headers ?? const {}),
              ),
            ),
          if (polylines.isNotEmpty)
            PolylineLayer(
              polylines: polylines
                  .map((m) => Polyline(
                        points: m.points,
                        color: Color(m.colorArgb),
                        strokeWidth: m.strokeWidth,
                      ))
                  .toList(),
            ),
          // MarkerLayer expects List<Marker>, but we receive List<Widget>
          // In the original code, markers were already Marker objects
          // We'll wrap them in a custom layer if needed
          ...markers,
          if (source?.attribution != null)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: RichAttributionWidget(
                  attributions: [TextSourceAttribution(source!.attribution!)],
                  alignment: AttributionAlignment.bottomRight,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void moveCamera(LatLng center, double zoom) {
    try {
      final cam = _controller.camera;
      if (cam.center != center || cam.zoom != zoom) {
        _controller.move(center, zoom);
      }
    } catch (_) {
      _controller.move(center, zoom);
    }
  }

  @override
  void fitBounds({
    required List<LatLng> coordinates,
    required EdgeInsets padding,
    double? maxZoom,
  }) {
    if (coordinates.isEmpty) return;
    final fit = CameraFit.coordinates(
      coordinates: coordinates,
      maxZoom: maxZoom ?? 17,
      padding: padding,
    );
    _controller.fitCamera(fit);
  }

  @override
  LatLng get currentCenter => _controller.camera.center;

  @override
  double get currentZoom => _controller.camera.zoom;

  @override
  bool supportsSource(MapSource source) {
    // Legacy adapter supports raster tiles (OSM-style)
    // It does NOT support vector tiles or MapLibre-specific sources
    return !source.urlTemplate.contains('mbtiles') &&
        !source.urlTemplate.contains('.pbf');
  }

  @override
  void dispose() {
    _controller.dispose();
  }

  String _withQueryParams(String template, Map<String, String>? qp) {
    if (qp == null || qp.isEmpty) return template;
    final sep = template.contains('?') ? '&' : '?';
    final suffix = qp.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    return '$template$sep$suffix';
  }
}
