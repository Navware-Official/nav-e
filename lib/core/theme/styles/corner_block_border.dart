import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/colors.dart';

class CornerBlockBorder extends OutlinedBorder {
  const CornerBlockBorder({
    this.borderRadius = BorderRadius.zero,
    this.blockOvershoot = 2.0,
    super.side = const BorderSide(width: 1.2, color: AppColors.lightGray),
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

    // 1) main outline
    final rrect = borderRadius.toRRect(rect);
    final paintBorder = side.toPaint()..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, paintBorder);

    // 2) corner caps (filled squares)
    final half = side.width / 2;
    final s = side.width + blockOvershoot * 2;
    final fill = Paint()
      ..color = side.color
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

    canvas.drawRect(tl, fill);
    canvas.drawRect(tr, fill);
    canvas.drawRect(bl, fill);
    canvas.drawRect(br, fill);
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
