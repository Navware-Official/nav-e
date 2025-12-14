import 'package:flutter/material.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/map_section.dart';
import 'package:nav_e/features/map_layers/models/marker_model.dart';
import 'package:nav_e/features/map_layers/models/polyline_model.dart';
import 'package:latlong2/latlong.dart';

/// Small wrapper that renders the MapWidget with provided
/// markers and polylines. Kept as a separate file to keep the main screen
/// focused on behavior rather than rendering details.
class PlanRouteMap extends StatelessWidget {
  final List<MarkerModel> markers;
  final List<PolylineModel> polylines;
  final void Function(LatLng latlng)? onMapTap;

  const PlanRouteMap({
    super.key,
    required this.markers,
    this.polylines = const [],
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return MapSection(
      extraMarkers: markers,
      onMapTap: onMapTap,
    );
  }
}
