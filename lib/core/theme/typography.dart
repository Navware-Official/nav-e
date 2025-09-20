import 'package:flutter/material.dart';
import 'colors.dart';

class AppTypography {
  static const family = 'NeueHaasUnica';

  static const TextTheme base = TextTheme(
    // Headings
    displayLarge:  TextStyle(fontFamily: family, fontWeight: FontWeight.w800),
    displayMedium: TextStyle(fontFamily: family, fontWeight: FontWeight.w700),
    displaySmall:  TextStyle(fontFamily: family, fontWeight: FontWeight.w600),

    headlineLarge:  TextStyle(fontFamily: family, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontFamily: family, fontWeight: FontWeight.w600),
    headlineSmall:  TextStyle(fontFamily: family, fontWeight: FontWeight.w600),

    // Titles / labels
    titleLarge:  TextStyle(fontFamily: family, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontFamily: family, fontWeight: FontWeight.w500),
    titleSmall:  TextStyle(fontFamily: family, fontWeight: FontWeight.w500),

    // Body
    bodyLarge:  TextStyle(fontFamily: family, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontFamily: family, fontWeight: FontWeight.w400),
    bodySmall:  TextStyle(fontFamily: family, fontWeight: FontWeight.w400),

    // Buttons / chips
    labelLarge:  TextStyle(fontFamily: family, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontFamily: family, fontWeight: FontWeight.w500),
    labelSmall:  TextStyle(fontFamily: family, fontWeight: FontWeight.w500),
  );

  static TextTheme light = base.apply(
    bodyColor: AppColors.capeCodDark01,
    displayColor: AppColors.blueRibbonDark04,
  );

  static TextTheme dark = base.apply(
    bodyColor: AppColors.white,
    displayColor: AppColors.blueRibbon,
  );
}
