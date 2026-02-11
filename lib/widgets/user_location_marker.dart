import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/components/decorations.dart';

class UserLocationMarker extends StatelessWidget {
  final double? heading;

  const UserLocationMarker({super.key, this.heading});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: AppDecorations.userLocationMarker,
      child: Transform.rotate(
        angle: (heading ?? 0) * math.pi / 180,
        child: Icon(
          Icons.navigation,
          size: 24,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
