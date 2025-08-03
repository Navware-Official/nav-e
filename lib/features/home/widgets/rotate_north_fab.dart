import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:nav_e/widgets/draggable_fab_widget.dart';

class RotateNorthFAB extends StatelessWidget {
  final MapController mapController;

  const RotateNorthFAB({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    return DraggableFAB(
      key: const Key('rotate_north_fab'),
      icon: Icons.explore,
      tooltip: 'Rotate map to North',
      shape: const CircleBorder(),
      onPressed: () {
        mapController.rotate(0.0);
      },
    );
  }
}
