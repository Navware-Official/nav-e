import 'package:flutter/material.dart';
import '../palette.dart';
import '../typography.dart';

/// AppBar themes — flat, hairline bottom border, display-font title.
class AppBarThemes {
  AppBarThemes._();

  static const AppBarTheme light = AppBarTheme(
    backgroundColor: AppPalette.paper000,
    foregroundColor: AppPalette.brandCharcoal,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontFamily: AppTypography.decorativeFamily,
      fontWeight: FontWeight.w600,
      fontSize: 22,
      letterSpacing: -0.22,
      color: AppPalette.brandCharcoal,
    ),
    shape: Border(bottom: BorderSide(width: 1, color: AppPalette.brandGray)),
  );

  static const AppBarTheme dark = AppBarTheme(
    backgroundColor: AppPalette.ink050,
    foregroundColor: AppPalette.brandWhite,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontFamily: AppTypography.decorativeFamily,
      fontWeight: FontWeight.w600,
      fontSize: 22,
      letterSpacing: -0.22,
      color: AppPalette.brandWhite,
    ),
    shape: Border(bottom: BorderSide(width: 1, color: AppPalette.ink400)),
  );
}
