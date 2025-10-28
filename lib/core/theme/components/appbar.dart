import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/styles/corner_block_border.dart';
import '../colors.dart';

class AppBarThemes {
  static const AppBarTheme light = AppBarTheme(
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.white,
    elevation: 0,
    shape: CornerBlockBorder(
      side: BorderSide(width: 2, color: AppColors.lightGray),
      blockOvershoot: 2,
    ),
  );

  static const AppBarTheme dark = AppBarTheme(
    backgroundColor: AppColors.blueRibbonDark04,
    foregroundColor: AppColors.lightGray,
    elevation: 2,
    shape: CornerBlockBorder(
      side: BorderSide(width: 2, color: AppColors.lightGray),
      blockOvershoot: 2,
    ),
  );
}
