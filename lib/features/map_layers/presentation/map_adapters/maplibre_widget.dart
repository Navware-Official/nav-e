import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

/// Converts a Color to hex string format for MapLibre (#RRGGBB).
String _colorToHex(Color color) {
  return '#${color.red.toRadixString(16).padLeft(2, '0')}'
      '${color.green.toRadixString(16).padLeft(2, '0')}'
      '${color.blue.toRadixString(16).padLeft(2, '0')}';
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
  final Function(LatLng)? onMapTap;
  final List<MapLibrePolyline> polylines;
  final List<MapLibreMarker> markers;

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
    this.onMapTap,
    this.polylines = const [],
    this.markers = const [],
  });

  @override
  State<MapLibreWidget> createState() => _MapLibreWidgetState();
}

class _MapLibreWidgetState extends State<MapLibreWidget> {
  ml.MapLibreMapController? _nativeController;
  MapLibreMapController? _controller;
  final Map<String, ml.Line> _polylineObjects = {};
  final Map<String, ml.Symbol> _markerSymbols = {};
  late Future<String> _styleFuture;

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
  }

  /// Loads the map style from URL, asset, or generates raster tile style.
  Future<String> _loadStyleString() async {
    // Custom style URL (HTTP/HTTPS or asset://)
    if (widget.styleUrl != null) {
      final styleUrl = widget.styleUrl!;
      
      // Handle asset:// protocol by loading from asset bundle
      if (styleUrl.startsWith('asset://')) {
        try {
          final assetPath = styleUrl.replaceFirst('asset://', '');
          final styleJson = await DefaultAssetBundle.of(context).loadString(assetPath);
          return styleJson;
        } catch (e) {
          debugPrint('[MapLibreWidget] Failed to load asset style: $e');
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
        }
      },
      'layers': [
        {
          'id': 'raster-layer',
          'type': 'raster',
          'source': 'raster-tiles',
          'minzoom': widget.minZoom,
          'maxzoom': widget.maxZoom,
        }
      ]
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
        
        return ml.MapLibreMap(
          styleString: snapshot.data!,
          initialCameraPosition: ml.CameraPosition(
            target: ml.LatLng(
              widget.initialCenter.latitude,
              widget.initialCenter.longitude,
            ),
            zoom: widget.initialZoom,
          ),
          onMapCreated: _handleMapCreated,
          onCameraIdle: _handleCameraIdle,
          onMapClick: widget.onMapTap != null 
          ? (point, coordinates) => widget.onMapTap!(
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
        );
      },
    );
  }

  void _handleMapCreated(ml.MapLibreMapController nativeController) async {
    _nativeController = nativeController;
    _controller = MapLibreMapController._(nativeController);
    
    // Initialize map overlays
    await _syncPolylines();
    await _syncMarkers();
    
    widget.onMapCreated?.call(_controller!);
  }

  void _handleCameraIdle() {
    if (_nativeController == null) return;
    
    final position = _nativeController!.cameraPosition;
    if (position != null && widget.onCameraMove != null) {
      widget.onCameraMove!(
        LatLng(position.target.latitude, position.target.longitude),
        position.zoom,
      );
    }
  }

  /// Synchronizes polylines with the map (removes old, adds new).
  Future<void> _syncPolylines() async {
    if (_nativeController == null) return;

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
            lineOpacity: polyline.color.opacity,
          ),
        );
        _polylineObjects[polyline.id] = line;
      } catch (e) {
        debugPrint('[MapLibreWidget] Error adding polyline ${polyline.id}: $e');
      }
    }
  }

  /// Synchronizes markers with the map (removes old, adds new).
  Future<void> _syncMarkers() async {
    if (_nativeController == null) return;

    // Remove existing markers
    for (final symbol in _markerSymbols.values) {
      await _nativeController!.removeSymbol(symbol);
    }
    _markerSymbols.clear();

    // Add new markers
    for (final marker in widget.markers) {
      try {
        final symbol = await _nativeController!.addSymbol(
          ml.SymbolOptions(
            geometry: ml.LatLng(
              marker.position.latitude,
              marker.position.longitude,
            ),
            iconSize: 1.5,
          ),
        );
        _markerSymbols[marker.id] = symbol;
      } catch (e) {
        debugPrint('[MapLibreWidget] Error adding marker ${marker.id}: $e');
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

  // ========== Camera Controls ==========
  
  /// Instantly moves the camera to the specified position and zoom level.
  void moveCamera(LatLng center, double zoom) {
    try {
      _native.moveCamera(
        ml.CameraUpdate.newLatLngZoom(
          ml.LatLng(center.latitude, center.longitude),
          zoom,
        ),
      );
    } catch (e) {
      // Silently ignore if map isn't ready yet
      debugPrint('[MapLibreMapController] moveCamera failed (map not ready): $e');
    }
  }

  /// Animates the camera to the specified position and zoom level.
  void animateCamera(LatLng center, double zoom, {Duration? duration}) {
    try {
      _native.animateCamera(
        ml.CameraUpdate.newLatLngZoom(
          ml.LatLng(center.latitude, center.longitude),
          zoom,
        ),
        duration: duration ?? const Duration(milliseconds: 500),
      );
    } catch (e) {
      // Silently ignore if map isn't ready yet
      debugPrint('[MapLibreMapController] animateCamera failed (map not ready): $e');
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
      debugPrint('[MapLibreMapController] fitBounds failed (map not ready): $e');
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
        geometry: points.map((p) => ml.LatLng(p.latitude, p.longitude)).toList(),
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
        geometry: newPoints.map((p) => ml.LatLng(p.latitude, p.longitude)).toList(),
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

  const MapLibreMarker({
    required this.id,
    required this.position,
    this.icon,
  });
  
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
