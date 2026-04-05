// Component theme template — copy this pattern when adding new component themes.
//
// Pattern:
//   1. One class per component in lib/core/theme/components/
//   2. Static light() and dark() factory methods
//   3. Use AppPalette for raw colour values (never Colors.*)
//   4. Register both variants in AppTheme.light() and AppTheme.dark()
import 'package:flutter/material.dart';
import '../palette.dart';

class AppBadgeThemes {
  AppBadgeThemes._();

  static BadgeThemeData light() => const BadgeThemeData(
    backgroundColor: AppPalette.blueRibbon,
    textColor: AppPalette.white,
    smallSize: 6,
    largeSize: 16,
  );

  static BadgeThemeData dark() => const BadgeThemeData(
    backgroundColor: AppPalette.blueRibbon,
    textColor: AppPalette.white,
    smallSize: 6,
    largeSize: 16,
  );
}
