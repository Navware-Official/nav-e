import 'package:flutter/material.dart';
import '../colors.dart';

class AppDecorations {
  static final BoxDecoration userLocationMarker = BoxDecoration(
    shape: BoxShape.circle,
    color: AppColors.white,
    border: Border.all(color: AppColors.blueRibbon, width: 2),
    boxShadow: const [
      BoxShadow(
        color: AppColors.blueRibbon,
        blurRadius: 10,
        spreadRadius: 1,
        offset: Offset(0, 1),
      ),
    ],
  );
}
