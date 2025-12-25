import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/colors.dart';

class CornerBlockBorder extends OutlinedBorder {
  const CornerBlockBorder({
    this.borderRadius = BorderRadius.zero,
    this.blockOvershoot = 2.0,
    super.side = const BorderSide(width: 4, color: AppColors.capeCodDark01),
  });

  final BorderRadius borderRadius;
  final double blockOvershoot;

  @override
  CornerBlockBorder copyWith({BorderSide? side}) {
    return CornerBlockBorder(
      side: side ?? this.side,
      borderRadius: borderRadius,
      blockOvershoot: blockOvershoot,
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final rrect = borderRadius.toRRect(rect);
    final path = Path()..addRRect(rrect);
    return path;
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final adjusted = rect.deflate(side.width);
    final rrect = borderRadius.toRRect(adjusted);
    final path = Path()..addRRect(rrect);
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;

    // Calculate corner block dimensions
    final half = side.width / 2;
    final s = side.width + blockOvershoot * 2;

    // Paint for border lines
    final borderPaint = Paint()
      ..color = side.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = side.width;

    // Paint for corner blocks (light gray fill)
    final cornerFill = Paint()
      ..color = AppColors.lightGray
      ..style = PaintingStyle.fill;

    // Define corner block rectangles
    final tl = Rect.fromLTWH(
      rect.left - blockOvershoot - half,
      rect.top - blockOvershoot - half,
      s,
      s,
    );
    final tr = Rect.fromLTWH(
      rect.right - s + blockOvershoot + half,
      rect.top - blockOvershoot - half,
      s,
      s,
    );
    final bl = Rect.fromLTWH(
      rect.left - blockOvershoot - half,
      rect.bottom - s + blockOvershoot + half,
      s,
      s,
    );
    final br = Rect.fromLTWH(
      rect.right - s + blockOvershoot + half,
      rect.bottom - s + blockOvershoot + half,
      s,
      s,
    );

    // Draw border lines between corners (not overlapping corner blocks)
    // Top line
    canvas.drawLine(
      Offset(tl.right, rect.top),
      Offset(tr.left, rect.top),
      borderPaint,
    );

    // Bottom line
    canvas.drawLine(
      Offset(bl.right, rect.bottom),
      Offset(br.left, rect.bottom),
      borderPaint,
    );

    // Left line
    canvas.drawLine(
      Offset(rect.left, tl.bottom),
      Offset(rect.left, bl.top),
      borderPaint,
    );

    // Right line
    canvas.drawLine(
      Offset(rect.right, tr.bottom),
      Offset(rect.right, br.top),
      borderPaint,
    );

    // Draw corner blocks on top
    canvas.drawRect(tl, cornerFill);
    canvas.drawRect(tr, cornerFill);
    canvas.drawRect(bl, cornerFill);
    canvas.drawRect(br, cornerFill);
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  CornerBlockBorder scale(double t) => CornerBlockBorder(
    side: side.scale(t),
    borderRadius: borderRadius * t,
    blockOvershoot: blockOvershoot * t,
  );
}
