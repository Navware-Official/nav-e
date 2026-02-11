import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/features/map_layers/models/marker_model.dart';
import 'package:nav_e/widgets/user_location_marker.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/map_widget.dart';

class MapSection extends StatelessWidget {
  final List<MarkerModel> extraMarkers;
  final void Function(LatLng latlng)? onMapTap;
  final void Function(LatLng latlng)? onMapLongPress;
  final void Function(String layerId, Map<String, dynamic> properties)? onDataLayerFeatureTap;

  const MapSection({
    super.key,
    required this.extraMarkers,
    this.onMapTap,
    this.onMapLongPress,
    this.onDataLayerFeatureTap,
  });

  /// Default position for test marker when user location is not yet available.
  static const LatLng _testMarkerPosition = LatLng(52.3791, 4.9);

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationBloc>().state;

    final markers = <MarkerModel>[
      ...extraMarkers,
      // Always show user location marker: real position when available, else test marker
      MarkerModel(
        id: 'user_location',
        position: location.position ?? _testMarkerPosition,
        icon: UserLocationMarker(heading: location.heading),
      ),
    ];

    return MapWidget(
      markers: markers,
      onMapTap: onMapTap,
      onMapLongPress: onMapLongPress,
      onDataLayerFeatureTap: onDataLayerFeatureTap,
    );
  }
}
