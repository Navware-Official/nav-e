import 'dart:async';
import 'dart:convert';
import 'dart:math' show Point;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/features/map_layers/models/data_layer_definition.dart';

/// Converts a Color to hex string format for MapLibre (#RRGGBB).
String _colorToHex(Color color) {
  final r = ((color.r * 255.0).round()).clamp(0, 255).toInt();
  final g = ((color.g * 255.0).round()).clamp(0, 255).toInt();
  final b = ((color.b * 255.0).round()).clamp(0, 255).toInt();

  return '#${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';
}

/// MapLibre GL map widget wrapper with support for vector and raster tiles.
/// Handles style loading from URLs, assets, or dynamically generated raster styles.
class MapLibreWidget extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final String? styleUrl;
  final String? rasterTileUrl;
  final int minZoom;
  final int maxZoom;
  final Function(MapLibreMapController)? onMapCreated;
  final Function(LatLng center, double zoom)? onCameraMove;
  final VoidCallback? onCameraIdle;
  final Function(LatLng)? onMapTap;
  /// Long press: e.g. reverse geosearch on home.
  final void Function(LatLng)? onMapLongPress;
  /// Called when the user taps a data layer feature (e.g. parking polygon).
  /// [layerId] is the data layer id (e.g. "parking"); [properties] are the GeoJSON feature properties.
  final void Function(String layerId, Map<String, dynamic> properties)? onDataLayerFeatureTap;
  final List<MapLibrePolyline> polylines;
  final List<MapLibreMarker> markers;
  final Set<String> enabledDataLayerIds;
  final List<DataLayerDefinition> dataLayerDefinitions;
  final int? markerFillColorArgb;
  final int? markerStrokeColorArgb;

  const MapLibreWidget({
    super.key,
    required this.initialCenter,
    required this.initialZoom,
    this.styleUrl,
    this.rasterTileUrl,
    this.minZoom = 0,
    this.maxZoom = 22,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.onMapTap,
    this.onMapLongPress,
    this.onDataLayerFeatureTap,
    this.polylines = const [],
    this.markers = const [],
    this.enabledDataLayerIds = const {},
    this.dataLayerDefinitions = const [],
    this.markerFillColorArgb,
    this.markerStrokeColorArgb,
  });

  @override
  State<MapLibreWidget> createState() => _MapLibreWidgetState();
}

class _MapLibreWidgetState extends State<MapLibreWidget> {
  ml.MapLibreMapController? _nativeController;
  MapLibreMapController? _controller;
  final Map<String, ml.Line> _polylineObjects = {};

  /// Native map circles used as markers (integrated into map layer).
  final Map<String, ml.Circle> _markerCircles = {};
  /// Data layer ids for which we have added source+layer (so we can remove them).
  final Set<String> _dataLayerIdsAdded = {};
  late Future<String> _styleFuture;
  bool _styleLoaded = false;

  @override
  void initState() {
    super.initState();
    _styleFuture = _loadStyleString();
  }

  @override
  void didUpdateWidget(MapLibreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload style if source parameters changed
    if (oldWidget.styleUrl != widget.styleUrl ||
        oldWidget.rasterTileUrl != widget.rasterTileUrl) {
      setState(() {
        _styleLoaded = false;
        _polylineObjects.clear();
        _markerCircles.clear();
        _dataLayerIdsAdded.clear();
        _styleFuture = _loadStyleString();
      });
    }

    // Update polylines if they changed
    if (widget.polylines != oldWidget.polylines) {
      _syncPolylines();
    }

    // Update markers if they changed
    if (widget.markers != oldWidget.markers) {
      _syncMarkers();
    }

    // Update data layers if enabled set or definitions changed
    if (widget.enabledDataLayerIds != oldWidget.enabledDataLayerIds ||
        widget.dataLayerDefinitions != oldWidget.dataLayerDefinitions) {
      _syncDataLayers();
    }
  }

  /// Loads the map style from URL, asset, or generates raster tile style.
  Future<String> _loadStyleString() async {
    // Custom style URL (HTTP/HTTPS or asset://)
    if (widget.styleUrl != null) {
      final styleUrl = widget.styleUrl!;

      // Handle asset:// protocol by loading from root bundle (reliable for any context)
      if (styleUrl.startsWith('asset://')) {
        try {
          final assetPath = styleUrl.replaceFirst('asset://', '');
          final styleJson = await rootBundle.loadString(assetPath);
          return styleJson;
        } catch (e, stack) {
          debugPrint('[MapLibreWidget] Failed to load asset style: $e');
          debugPrint('[MapLibreWidget] $stack');
          return ml.MapLibreStyles.demo;
        }
      }

      return styleUrl;
    }

    // Raster tile URL - generate MapLibre style JSON
    if (widget.rasterTileUrl != null) {
      return _generateRasterTileStyle(widget.rasterTileUrl!);
    }

    // Fallback to demo style
    return ml.MapLibreStyles.demo;
  }

  /// Generates a MapLibre GL style JSON for raster tiles.
  String _generateRasterTileStyle(String tileUrl) {
    return jsonEncode({
      'version': 8,
      'sources': {
        'raster-tiles': {
          'type': 'raster',
          'tiles': [tileUrl],
          'tileSize': 256,
          'minzoom': widget.minZoom,
          'maxzoom': widget.maxZoom,
        },
      },
      'layers': [
        {
          'id': 'raster-layer',
          'type': 'raster',
          'source': 'raster-tiles',
          'minzoom': widget.minZoom,
          'maxzoom': widget.maxZoom,
        },
      ],
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _styleFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading map style: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            ml.MapLibreMap(
              styleString: snapshot.data!,
              initialCameraPosition: ml.CameraPosition(
                target: ml.LatLng(
                  widget.initialCenter.latitude,
                  widget.initialCenter.longitude,
                ),
                zoom: widget.initialZoom,
              ),
              onMapCreated: _handleMapCreated,
              onStyleLoadedCallback: _handleStyleLoaded,
              onCameraMove: _handleCameraMove,
              onCameraIdle: _handleCameraIdle,
              onMapClick: (widget.onMapTap != null ||
                      (widget.onDataLayerFeatureTap != null &&
                          widget.enabledDataLayerIds.isNotEmpty))
                  ? (point, coordinates) => _handleMapClick(
                        point,
                        LatLng(coordinates.latitude, coordinates.longitude),
                      )
                  : null,
              onMapLongClick: widget.onMapLongPress != null
                  ? (point, coordinates) => _handleMapLongClick(
                        LatLng(coordinates.latitude, coordinates.longitude),
                      )
                  : null,
              trackCameraPosition: true,
              myLocationEnabled: false,
              compassEnabled: true,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
              doubleClickZoomEnabled: true,
            ),
          ],
        );
      },
    );
  }

  void _handleMapCreated(ml.MapLibreMapController nativeController) async {
    setState(() {
      _nativeController = nativeController;
      _controller = MapLibreMapController._(nativeController);
    });

    if (_styleLoaded) {
      await _syncPolylines();
      await _syncMarkers();
    }

    if (mounted) widget.onMapCreated?.call(_controller!);
  }

  void _handleStyleLoaded() async {
    _styleLoaded = true;
    debugPrint('[MapLibreWidget] style loaded');
    _polylineObjects.clear();
    _markerCircles.clear();
    _dataLayerIdsAdded.clear();
    await _syncPolylines();
    await _syncMarkers();
    await _syncDataLayers();
  }

  void _handleCameraMove(ml.CameraPosition position) {
    widget.onCameraMove?.call(
      LatLng(position.target.latitude, position.target.longitude),
      position.zoom,
    );
  }

  void _handleCameraIdle() {
    if (_nativeController == null) return;

    widget.onCameraIdle?.call();

    final position = _nativeController!.cameraPosition;
    if (position != null && widget.onCameraMove != null) {
      widget.onCameraMove!(
        LatLng(position.target.latitude, position.target.longitude),
        position.zoom,
      );
    }
  }

  /// Handles tap: data layer feature hit → onDataLayerFeatureTap; else → onMapTap.
  void _handleMapClick(Point point, LatLng coordinates) {
    if (widget.onDataLayerFeatureTap != null &&
        widget.enabledDataLayerIds.isNotEmpty &&
        _nativeController != null) {
      final layerIds = widget.enabledDataLayerIds
          .map((id) => 'data-layer-$id')
          .toList();
      final pt = Point<double>(point.x.toDouble(), point.y.toDouble());
      _nativeController!
          .queryRenderedFeatures(pt, layerIds, null)
          .then((features) {
        if (features.isNotEmpty) {
          final first = features[0];
          if (first is Map<String, dynamic>) {
            final props = first['properties'];
            final layer = first['layer'];
            final propsMap = props is Map
                ? Map<String, dynamic>.from(props)
                : <String, dynamic>{};
            final layerId = layer is Map
                ? (layer['id'] as String?) ?? ''
                : layer?.toString() ?? '';
            final dataLayerId = layerId.startsWith('data-layer-')
                ? layerId.substring('data-layer-'.length)
                : layerId;
            if (dataLayerId.isNotEmpty) {
              widget.onDataLayerFeatureTap?.call(dataLayerId, propsMap);
              return;
            }
          }
        }
        widget.onMapTap?.call(coordinates);
      }).catchError((_) {
        widget.onMapTap?.call(coordinates);
      });
    } else {
      widget.onMapTap?.call(coordinates);
    }
  }

  /// Handles long press: e.g. reverse geosearch (onMapLongPress).
  void _handleMapLongClick(LatLng coordinates) {
    widget.onMapLongPress?.call(coordinates);
  }

  /// Synchronizes polylines with the map (removes old, adds new).
  Future<void> _syncPolylines() async {
    if (_nativeController == null || !_styleLoaded) return;

    // Remove existing polylines
    for (final line in _polylineObjects.values) {
      await _nativeController!.removeLine(line);
    }
    _polylineObjects.clear();

    // Add new polylines
    for (final polyline in widget.polylines) {
      try {
        final line = await _nativeController!.addLine(
          ml.LineOptions(
            geometry: polyline.points
                .map((p) => ml.LatLng(p.latitude, p.longitude))
                .toList(),
            lineColor: _colorToHex(polyline.color),
            lineWidth: polyline.width,
            lineOpacity: polyline.color.a,
          ),
        );
        _polylineObjects[polyline.id] = line;
      } catch (e) {
        debugPrint('[MapLibreWidget] Error adding polyline ${polyline.id}: $e');
      }
    }
  }

  /// Syncs data layers (GeoJSON overlays): add source+layer for enabled ids,
  /// remove layer+source for disabled ids.
  Future<void> _syncDataLayers() async {
    if (_nativeController == null || !_styleLoaded) return;

    final definitionsById = {
      for (final d in widget.dataLayerDefinitions) d.id: d
    };

    // Remove layers that are no longer enabled
    for (final id in _dataLayerIdsAdded.toList()) {
      if (!widget.enabledDataLayerIds.contains(id)) {
        try {
          final layerId = 'data-layer-$id';
          final sourceId = 'data-source-$id';
          await _nativeController!.removeLayer(layerId);
          await _nativeController!.removeSource(sourceId);
          _dataLayerIdsAdded.remove(id);
        } catch (e) {
          debugPrint('[MapLibreWidget] Error removing data layer $id: $e');
        }
      }
    }

    // Add layers that are enabled and have a definition
    for (final id in widget.enabledDataLayerIds) {
      if (_dataLayerIdsAdded.contains(id)) continue;
      final definition = definitionsById[id];
      if (definition == null) continue;

      try {
        final jsonString = await rootBundle.loadString(definition.geojsonAssetPath);
        final geojsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final sourceId = 'data-source-$id';
        final layerId = 'data-layer-$id';

        await _nativeController!.addGeoJsonSource(sourceId, geojsonMap);

        switch (definition.geometryType) {
          case DataLayerGeometryType.fill:
            await _nativeController!.addFillLayer(
              sourceId,
              layerId,
              const ml.FillLayerProperties(
                fillColor: '#3388ff',
                fillOpacity: 0.4,
                fillOutlineColor: '#3388ff',
              ),
            );
            break;
          case DataLayerGeometryType.circle:
            await _nativeController!.addCircleLayer(
              sourceId,
              layerId,
              const ml.CircleLayerProperties(
                circleColor: '#3388ff',
                circleRadius: 6,
                circleStrokeWidth: 1,
                circleStrokeColor: '#2266cc',
              ),
            );
            break;
          case DataLayerGeometryType.line:
            await _nativeController!.addLineLayer(
              sourceId,
              layerId,
              const ml.LineLayerProperties(
                lineColor: '#3388ff',
                lineWidth: 2,
              ),
            );
            break;
        }
        _dataLayerIdsAdded.add(id);
      } catch (e) {
        debugPrint(
          '[MapLibreWidget] Error adding data layer ${definition.id}: $e',
        );
      }
    }
  }

  /// Syncs markers as native circles on the map (integrated into map layer).
  /// Only updates when marker positions change (e.g. user location update).
  Future<void> _syncMarkers() async {
    if (_nativeController == null || !_styleLoaded) return;

    final currentIds = widget.markers.map((m) => m.id).toSet();

    // Remove circles for markers that are no longer in the list
    for (final id in _markerCircles.keys.toList()) {
      if (!currentIds.contains(id)) {
        await _nativeController!.removeCircle(_markerCircles[id]!);
        _markerCircles.remove(id);
      }
    }

    final fillColor = widget.markerFillColorArgb != null
        ? Color(widget.markerFillColorArgb!)
        : AppColors.blueRibbon;
    final strokeColor = widget.markerStrokeColorArgb != null
        ? Color(widget.markerStrokeColorArgb!)
        : AppColors.white;

    // Add or update circles for each marker
    for (final marker in widget.markers) {
      final pos = ml.LatLng(
        marker.position.latitude,
        marker.position.longitude,
      );
      final options = ml.CircleOptions(
        geometry: pos,
        circleRadius: 12,
        circleColor: _colorToHex(fillColor),
        circleStrokeWidth: 2,
        circleStrokeColor: _colorToHex(strokeColor),
      );
      if (_markerCircles.containsKey(marker.id)) {
        try {
          await _nativeController!.updateCircle(
            _markerCircles[marker.id]!,
            options,
          );
        } catch (e) {
          debugPrint(
            '[MapLibreWidget] updateCircle failed, recreating ${marker.id}: $e',
          );
          final circle = await _nativeController!.addCircle(options);
          _markerCircles[marker.id] = circle;
        }
      } else {
        final circle = await _nativeController!.addCircle(options);
        _markerCircles[marker.id] = circle;
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _nativeController?.dispose();
    super.dispose();
  }
}

/// High-level controller for MapLibre map operations.
/// Provides convenient methods for camera control, markers, and polylines.
class MapLibreMapController {
  final ml.MapLibreMapController _native;

  MapLibreMapController._(this._native);

  /// Native controller for advanced use.
  ml.MapLibreMapController get native => _native;

  // ========== Camera Controls ==========

  /// Instantly moves the camera to the specified position and zoom level.
  void moveCamera(
    LatLng center,
    double zoom, {
    double? tilt,
    double? bearing,
  }) {
    try {
      if (tilt == null && bearing == null) {
        _native.moveCamera(
          ml.CameraUpdate.newLatLngZoom(
            ml.LatLng(center.latitude, center.longitude),
            zoom,
          ),
        );
      } else {
        final pos = _native.cameraPosition;
        _native.moveCamera(
          ml.CameraUpdate.newCameraPosition(
            ml.CameraPosition(
              target: ml.LatLng(center.latitude, center.longitude),
              zoom: zoom,
              bearing: bearing ?? pos?.bearing ?? 0.0,
              tilt: tilt ?? pos?.tilt ?? 0.0,
            ),
          ),
        );
      }
    } catch (e) {
      // Silently ignore if map isn't ready yet
      debugPrint(
        '[MapLibreMapController] moveCamera failed (map not ready): $e',
      );
    }
  }

  /// Animates the camera to the specified position and zoom level.
  void animateCamera(
    LatLng center,
    double zoom, {
    Duration? duration,
    double? tilt,
    double? bearing,
  }) {
    try {
      if (tilt == null && bearing == null) {
        _native.animateCamera(
          ml.CameraUpdate.newLatLngZoom(
            ml.LatLng(center.latitude, center.longitude),
            zoom,
          ),
          duration: duration ?? const Duration(milliseconds: 500),
        );
      } else {
        final pos = _native.cameraPosition;
        _native.animateCamera(
          ml.CameraUpdate.newCameraPosition(
            ml.CameraPosition(
              target: ml.LatLng(center.latitude, center.longitude),
              zoom: zoom,
              bearing: bearing ?? pos?.bearing ?? 0.0,
              tilt: tilt ?? pos?.tilt ?? 0.0,
            ),
          ),
          duration: duration ?? const Duration(milliseconds: 500),
        );
      }
    } catch (e) {
      // Silently ignore if map isn't ready yet
      debugPrint(
        '[MapLibreMapController] animateCamera failed (map not ready): $e',
      );
    }
  }

  /// Adjusts the camera to fit all coordinates within the viewport.
  void fitBounds(List<LatLng> coordinates, {EdgeInsets? padding}) {
    if (coordinates.isEmpty) return;

    // Calculate bounds
    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;

    for (final coord in coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    try {
      _native.animateCamera(
        ml.CameraUpdate.newLatLngBounds(
          ml.LatLngBounds(
            southwest: ml.LatLng(minLat, minLng),
            northeast: ml.LatLng(maxLat, maxLng),
          ),
          left: padding?.left ?? 50,
          top: padding?.top ?? 50,
          right: padding?.right ?? 50,
          bottom: padding?.bottom ?? 50,
        ),
      );
    } catch (e) {
      // Silently ignore if map isn't ready yet
      debugPrint(
        '[MapLibreMapController] fitBounds failed (map not ready): $e',
      );
    }
  }

  /// Zooms in by one level.
  void zoomIn() {
    _native.animateCamera(ml.CameraUpdate.zoomIn());
  }

  /// Zooms out by one level.
  void zoomOut() {
    _native.animateCamera(ml.CameraUpdate.zoomOut());
  }

  /// Sets the zoom level.
  void setZoom(double zoom) {
    _native.animateCamera(ml.CameraUpdate.zoomTo(zoom));
  }

  // ========== Markers ==========

  /// Adds a marker to the map and returns the symbol object.
  Future<ml.Symbol> addMarker(
    LatLng position, {
    String? iconImage,
    double iconSize = 1.0,
    double? iconRotation,
  }) async {
    return await _native.addSymbol(
      ml.SymbolOptions(
        geometry: ml.LatLng(position.latitude, position.longitude),
        iconImage: iconImage,
        iconSize: iconSize,
        iconRotate: iconRotation,
      ),
    );
  }

  /// Removes a marker from the map.
  Future<void> removeMarker(ml.Symbol symbol) async {
    await _native.removeSymbol(symbol);
  }

  /// Updates a marker's position.
  Future<void> updateMarker(ml.Symbol symbol, LatLng newPosition) async {
    await _native.updateSymbol(
      symbol,
      ml.SymbolOptions(
        geometry: ml.LatLng(newPosition.latitude, newPosition.longitude),
      ),
    );
  }

  // ========== Polylines ==========

  /// Adds a polyline to the map and returns the line object.
  Future<ml.Line> addPolyline(
    List<LatLng> points, {
    required Color color,
    double width = 4.0,
    double opacity = 1.0,
  }) async {
    return await _native.addLine(
      ml.LineOptions(
        geometry: points
            .map((p) => ml.LatLng(p.latitude, p.longitude))
            .toList(),
        lineColor: _colorToHex(color),
        lineWidth: width,
        lineOpacity: opacity,
      ),
    );
  }

  /// Removes a polyline from the map.
  Future<void> removePolyline(ml.Line line) async {
    await _native.removeLine(line);
  }

  /// Updates a polyline's points.
  Future<void> updatePolyline(ml.Line line, List<LatLng> newPoints) async {
    await _native.updateLine(
      line,
      ml.LineOptions(
        geometry: newPoints
            .map((p) => ml.LatLng(p.latitude, p.longitude))
            .toList(),
      ),
    );
  }

  // ========== Getters ==========

  /// Gets the current camera center position.
  LatLng get center {
    final pos = _native.cameraPosition;
    return pos != null
        ? LatLng(pos.target.latitude, pos.target.longitude)
        : const LatLng(0, 0);
  }

  /// Gets the current zoom level.
  double get zoom => _native.cameraPosition?.zoom ?? 13.0;

  /// Gets the current camera bearing (rotation).
  double get bearing => _native.cameraPosition?.bearing ?? 0.0;

  /// Gets the current camera tilt.
  double get tilt => _native.cameraPosition?.tilt ?? 0.0;

  /// Resets the camera bearing to north (0°).
  void resetBearing() {
    try {
      final pos = _native.cameraPosition;
      if (pos == null) return;
      _native.moveCamera(
        ml.CameraUpdate.newCameraPosition(
          ml.CameraPosition(
            target: pos.target,
            zoom: pos.zoom,
            bearing: 0.0,
            tilt: pos.tilt,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[MapLibreMapController] resetBearing failed: $e');
    }
  }

  void dispose() {
    _native.dispose();
  }
}

/// Represents a polyline on the MapLibre map
class MapLibrePolyline {
  final String id;
  final List<LatLng> points;
  final Color color;
  final double width;

  const MapLibrePolyline({
    required this.id,
    required this.points,
    required this.color,
    this.width = 4.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapLibrePolyline &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          points == other.points &&
          color == other.color &&
          width == other.width;

  @override
  int get hashCode =>
      id.hashCode ^ points.hashCode ^ color.hashCode ^ width.hashCode;
}

/// Represents a marker on the MapLibre map
class MapLibreMarker {
  final String id;
  final LatLng position;
  final Widget? icon;

  const MapLibreMarker({required this.id, required this.position, this.icon});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapLibreMarker &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          position == other.position;

  @override
  int get hashCode => id.hashCode ^ position.hashCode;
}
