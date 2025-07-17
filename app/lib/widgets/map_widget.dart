import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;

  const MapWidget({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter:
            LatLng(0, 0),
        initialZoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'nav_e.navware',
        ),
      ],
    );
  }
}
