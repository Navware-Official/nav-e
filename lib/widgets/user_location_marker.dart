import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Directional navigation arrow — points toward [heading] (degrees, 0 = north,
/// clockwise). When [heading] is null the widget falls back to a stationary
/// position dot with an accuracy aura.
class UserLocationMarker extends StatelessWidget {
  const UserLocationMarker({super.key, this.heading});

  final double? heading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (heading == null) {
      return SizedBox(
        width: 44,
        height: 44,
        child: CustomPaint(
          painter: _DotPainter(
            fillColor: colorScheme.primary,
            outlineColor: colorScheme.surface,
          ),
        ),
      );
    }

    return Transform.rotate(
      angle: heading! * math.pi / 180,
      child: SizedBox(
        width: 44,
        height: 44,
        child: CustomPaint(
          painter: _ArrowPainter(
            fillColor: colorScheme.primary,
            outlineColor: colorScheme.surface,
          ),
        ),
      ),
    );
  }
}

// ── Arrow painter (heading known) ────────────────────────────────────────────

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.fillColor, required this.outlineColor});

  final Color fillColor;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Navigation arrow: nose at top, concave swept wings, notched tail.
    // All coordinates are relative to the 44×44 canvas; arrow points up (north).
    final path = Path()
      ..moveTo(cx, h * 0.09)            // nose
      ..lineTo(cx + w * 0.44, h * 0.76) // right wing tip
      ..lineTo(cx + w * 0.18, h * 0.58) // right inner concave
      ..lineTo(cx, h * 0.88)            // tail centre
      ..lineTo(cx - w * 0.18, h * 0.58) // left inner concave
      ..lineTo(cx - w * 0.44, h * 0.76) // left wing tip
      ..close();

    // Drop shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.35), 4, true);

    // Fill
    canvas.drawPath(path, Paint()..color = fillColor);

    // Outline
    canvas.drawPath(
      path,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) =>
      old.fillColor != fillColor || old.outlineColor != outlineColor;
}

// ── Dot painter (no heading) ─────────────────────────────────────────────────

class _DotPainter extends CustomPainter {
  const _DotPainter({required this.fillColor, required this.outlineColor});

  final Color fillColor;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dotRadius = size.width * 0.25;

    // Accuracy aura
    canvas.drawCircle(
      center,
      size.width * 0.46,
      Paint()..color = fillColor.withValues(alpha: 0.18),
    );

    // White outline ring
    canvas.drawCircle(
      center,
      dotRadius + 2.5,
      Paint()..color = outlineColor,
    );

    // Filled dot
    canvas.drawCircle(center, dotRadius, Paint()..color = fillColor);
  }

  @override
  bool shouldRepaint(covariant _DotPainter old) =>
      old.fillColor != fillColor || old.outlineColor != outlineColor;
}
