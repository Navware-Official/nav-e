import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/components/decorations.dart';

class UserLocationMarker extends StatelessWidget {
  final double? heading;

  const UserLocationMarker({super.key, this.heading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: AppDecorations.userLocationMarker,
      child: Transform.rotate(
        angle: (heading ?? 0) * math.pi / 180,
        child: const Icon(Icons.navigation, size: 30),
      ),
    );
  }
}
