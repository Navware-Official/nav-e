import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/components/decorations.dart';

/// Paints an arrow pointing up (north), to be rotated by [UserLocationMarker]
/// so it shows the device heading.
class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;

    // Circle at base (you are here)
    canvas.drawCircle(center, radius * 0.35, Paint()..color = color);

    // Arrow head pointing up: triangle from center upward
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx - radius * 0.55, center.dy + radius * 0.35)
      ..lineTo(center.dx - radius * 0.2, center.dy)
      ..lineTo(center.dx, center.dy + radius * 0.15)
      ..lineTo(center.dx + radius * 0.2, center.dy)
      ..lineTo(center.dx + radius * 0.55, center.dy + radius * 0.35)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class UserLocationMarker extends StatelessWidget {
  final double? heading;

  const UserLocationMarker({super.key, this.heading});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primary;
    return Container(
      width: 40,
      height: 40,
      decoration: AppDecorations.userLocationMarker,
      child: Transform.rotate(
        angle: (heading ?? 0) * math.pi / 180,
        child: CustomPaint(
          size: const Size(40, 40),
          painter: _ArrowPainter(color: color),
        ),
      ),
    );
  }
}
