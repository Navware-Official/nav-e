import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/styles/corner_block_border.dart';
import '../palette.dart';

class AppBarThemes {
  static const AppBarTheme light = AppBarTheme(
    backgroundColor: AppPalette.white,
    foregroundColor: AppPalette.capeCodDark02,
    elevation: 0,
    shape: CornerBlockBorder(
      side: BorderSide(width: 2, color: AppPalette.lightGray),
      blockOvershoot: 2,
    ),
  );

  static const AppBarTheme dark = AppBarTheme(
    backgroundColor: AppPalette.blueRibbonDark04,
    foregroundColor: AppPalette.lightGray,
    elevation: 2,
    shape: CornerBlockBorder(
      side: BorderSide(width: 2, color: AppPalette.lightGray),
      blockOvershoot: 2,
    ),
  );
}
