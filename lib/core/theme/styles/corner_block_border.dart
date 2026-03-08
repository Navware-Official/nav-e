import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/palette.dart';

/// A sharp rectangular border with filled square blocks at each corner.
///
/// The blocks extend [blockOvershoot] pixels beyond the widget's bounding rect,
/// so the parent must not clip — set [clipBehavior: Clip.none] where needed.
///
/// [blockFillColor] controls the fill of the corner squares. Defaults to
/// [AppPalette.lightGray] to match the app's surface/background color.
class CornerBlockBorder extends OutlinedBorder {
  const CornerBlockBorder({
    this.borderRadius = BorderRadius.zero,
    this.blockOvershoot = 2.0,
    this.blockFillColor = AppPalette.lightGray,
    super.side = const BorderSide(width: 4, color: AppPalette.capeCodDark01),
  });

  final BorderRadius borderRadius;
  final double blockOvershoot;

  /// Fill colour of the corner block squares.
  final Color blockFillColor;

  @override
  CornerBlockBorder copyWith({
    BorderSide? side,
    BorderRadius? borderRadius,
    double? blockOvershoot,
    Color? blockFillColor,
  }) {
    return CornerBlockBorder(
      side: side ?? this.side,
      borderRadius: borderRadius ?? this.borderRadius,
      blockOvershoot: blockOvershoot ?? this.blockOvershoot,
      blockFillColor: blockFillColor ?? this.blockFillColor,
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.toRRect(rect));
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.toRRect(rect.deflate(side.width)));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;

    final half = side.width / 2;
    final s = side.width + blockOvershoot * 2;

    final borderPaint = Paint()
      ..color = side.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = side.width;

    final cornerFill = Paint()
      ..color = blockFillColor
      ..style = PaintingStyle.fill;

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

    // Lines between corners
    canvas.drawLine(
      Offset(tl.right, rect.top),
      Offset(tr.left, rect.top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(bl.right, rect.bottom),
      Offset(br.left, rect.bottom),
      borderPaint,
    );
    canvas.drawLine(
      Offset(rect.left, tl.bottom),
      Offset(rect.left, bl.top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(rect.right, tr.bottom),
      Offset(rect.right, br.top),
      borderPaint,
    );

    // Corner blocks drawn on top
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
    blockFillColor: blockFillColor,
  );
}
