import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:nav_e/core/bloc/map_bloc.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final List<Marker> markers;
  final void Function(dynamic position, bool hasGesture)? onMapInteraction;

  const MapWidget({
    super.key,
    required this.mapController,
    required this.markers, this.onMapInteraction,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: state.center,
            initialZoom: state.zoom,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                context.read<MapBloc>().add(ToggleFollowUser(false));
              }

              final center = position.center;
              final zoom = position.zoom;
              context.read<MapBloc>().add(MapMoved(center, zoom));
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'nav_e.navware',
              
            ),
            MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }
}
