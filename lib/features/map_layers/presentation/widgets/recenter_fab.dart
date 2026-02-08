import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';
import 'package:nav_e/widgets/draggable_fab_widget.dart';

class RecenterFAB extends StatelessWidget {
  const RecenterFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, mapState) {
        final isFollowing = mapState.followUser;
        final location = context.watch<LocationBloc>().state.position;

        return DraggableFAB(
          key: const Key('recenter_fab'),
          icon: Icons.my_location,
          tooltip: 'Recenter map to user location',
          iconColor: isFollowing ? Colors.white : Colors.lightBlue,
          onPressed: () {
            final bloc = context.read<MapBloc>();
            final mapState = bloc.state;
            debugPrint(
              '[RecenterFAB] pressed | followUser=${mapState.followUser} '
              'center=${mapState.center} zoom=${mapState.zoom} '
              'location=${location ?? 'null'}',
            );
            if (location != null) {
              bloc.add(ToggleFollowUser(true));
              bloc.add(MapMoved(location, 16.0, force: true));
            } else {
              bloc.add(ToggleFollowUser(true));
            }
          },
        );
      },
    );
  }
}
