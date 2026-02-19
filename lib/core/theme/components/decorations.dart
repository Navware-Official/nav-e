import 'package:flutter/material.dart';
import '../colors.dart';

class AppDecorations {
  static final BoxDecoration userLocationMarker = BoxDecoration(
    shape: BoxShape.circle,
    color: AppColors.white,
    border: Border.all(color: AppColors.blueRibbonDark02, width: 2),
    boxShadow: const [
      BoxShadow(
        color: AppColors.blueRibbonDark02,
        blurRadius: 12,
        spreadRadius: 2,
        offset: Offset(0, 1),
      ),
    ],
  );
}
