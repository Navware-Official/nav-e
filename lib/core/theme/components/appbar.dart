import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/styles/corner_block_border.dart';
import '../palette.dart';
import '../typography.dart';

class AppBarThemes {
  static const AppBarTheme light = AppBarTheme(
    backgroundColor: AppPalette.white,
    foregroundColor: AppPalette.capeCodDark02,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: AppTypography.decorativeFamily,
      fontWeight: FontWeight.w600,
      fontSize: 22,
      color: AppPalette.capeCodDark02,
    ),
    shape: CornerBlockBorder(
      side: BorderSide(width: 2, color: AppPalette.lightGray),
      blockOvershoot: 2,
    ),
  );

  static const AppBarTheme dark = AppBarTheme(
    backgroundColor: AppPalette.blueRibbonDark04,
    foregroundColor: AppPalette.lightGray,
    elevation: 2,
    titleTextStyle: TextStyle(
      fontFamily: AppTypography.decorativeFamily,
      fontWeight: FontWeight.w600,
      fontSize: 22,
      color: AppPalette.lightGray,
    ),
    shape: CornerBlockBorder(
      side: BorderSide(width: 2, color: AppPalette.lightGray),
      blockOvershoot: 2,
    ),
  );
}
