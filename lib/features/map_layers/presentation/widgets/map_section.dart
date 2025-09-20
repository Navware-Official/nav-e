import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/widgets/user_location_marker.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/map_widget.dart';

class MapSection extends StatelessWidget {
  final MapController mapController;
  final List<Marker> extraMarkers;

  const MapSection({
    super.key,
    required this.mapController,
    required this.extraMarkers,
  });

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationBloc>().state;
    final followUser = context.watch<MapBloc>().state.followUser;

    final userMarker = UserLocationMarker(
      position: location.position,
      heading: location.heading,
    );

    return BlocListener<LocationBloc, LocationState>(
      listenWhen: (prev, curr) => curr.position != prev.position,
      listener: (context, state) {
        if (followUser && state.position != null) {
          mapController.move(state.position!, 16.0);
          if (state.heading != null && state.heading!.isFinite) {
            mapController.rotate(state.heading!);
          }
        }
      },
      child: MapWidget(
        mapController: mapController,
        markers: [userMarker, ...extraMarkers],
        onMapInteraction: (pos, hasGesture) {
          if (hasGesture) {
            context.read<MapBloc>().add(ToggleFollowUser(false));
          }
          context.read<MapBloc>().add(MapMoved(pos.center, pos.zoom));
        },
      ),
    );
  }
}
