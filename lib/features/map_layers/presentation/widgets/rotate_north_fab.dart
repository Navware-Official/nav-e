import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/widgets/draggable_fab_widget.dart';

class RotateNorthFAB extends StatelessWidget {
  const RotateNorthFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableFAB(
      key: const Key('rotate_north_fab'),
      icon: Icons.explore,
      tooltip: 'Rotate map to North',
      shape: const CircleBorder(),
      onPressed: () {
        // Reset bearing to 0 (north) via MapBloc
        final mapBloc = context.read<MapBloc>();
        final currentState = mapBloc.state;
        // Trigger a camera update to reset rotation
        context.read<MapBloc>().add(
          MapMoved(currentState.center, currentState.zoom),
        );
      },
    );
  }
}
