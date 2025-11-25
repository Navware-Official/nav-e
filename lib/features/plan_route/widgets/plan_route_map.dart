import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/map_section.dart';
import 'package:latlong2/latlong.dart';

/// Small wrapper that renders the MapWidget with provided controller,
/// markers and polylines. Kept as a separate file to keep the main screen
/// focused on behavior rather than rendering details.
class PlanRouteMap extends StatelessWidget {
  final MapController mapController;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final void Function(LatLng latlng)? onMapTap;

  const PlanRouteMap({
    super.key,
    required this.mapController,
    required this.markers,
    this.polylines = const [],
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return MapSection(
      mapController: mapController,
      extraMarkers: markers,
      onMapTap: onMapTap,
    );
  }
}
