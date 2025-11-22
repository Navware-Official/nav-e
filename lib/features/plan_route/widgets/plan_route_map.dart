import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:nav_e/features/map_layers/presentation/map_widget.dart';

/// Small wrapper that renders the MapWidget with provided controller,
/// markers and polylines. Kept as a separate file to keep the main screen
/// focused on behavior rather than rendering details.
class PlanRouteMap extends StatelessWidget {
  final MapController mapController;
  final List<Marker> markers;
  final List<Polyline> polylines;

  const PlanRouteMap({
    super.key,
    required this.mapController,
    required this.markers,
    this.polylines = const [],
  });

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      mapController: mapController,
      markers: markers,
      polylines: polylines,
    );
  }
}
