import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';
import 'package:nav_e/widgets/draggable_fab_widget.dart';

class RecenterFAB extends StatelessWidget {
  final MapController mapController;

  const RecenterFAB({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    final location = context.read<LocationBloc>().state.position;
    final heading = context.read<LocationBloc>().state.heading;

    return BlocBuilder<MapBloc, MapState>(
      builder: (context, mapState) {
        final isFollowing = mapState.followUser;

        return DraggableFAB(
          key: const Key('recenter_fab'),
          icon: Icons.my_location,
          tooltip: 'Recenter map to user location',
          iconColor: isFollowing ? Colors.white : Colors.lightBlue,
          onPressed: () {
            context.read<MapBloc>().add(ToggleFollowUser(true));

            if (location != null) {
              mapController.move(location, 16.0);
              if (heading != null && heading.isFinite) {
                mapController.rotate(heading);
              }
            }
          },
        );
      },
    );
  }
}
