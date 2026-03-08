import 'package:flutter/material.dart';
import 'palette.dart';

/// App typography. Prefer Theme.of(context).textTheme (titleLarge, bodyMedium,
/// etc.) for all text; avoid raw TextStyle for body/title so theme and dark mode stay consistent.
///
/// [family] (NeueHaasUnica) is used for body, titles, and labels.
/// [decorativeFamily] (BitcountGridSingle) is used for display and headline styles.
class AppTypography {
  static const family = 'NeueHaasUnica';

  /// Decorative font for display/headline text. Use [decorativeFamily] or display* / headline* styles.
  static const decorativeFamily = 'BitcountGridSingle';
  @Deprecated(
    'Use decorativeFamily for display/headline; use family for body text',
  )
  static const subFamily = decorativeFamily;

  static const TextTheme base = TextTheme(
    // Display & headline: decorative font
    displayLarge: TextStyle(
      fontFamily: decorativeFamily,
      fontWeight: FontWeight.w800,
    ),
    displayMedium: TextStyle(
      fontFamily: decorativeFamily,
      fontWeight: FontWeight.w700,
    ),
    displaySmall: TextStyle(
      fontFamily: decorativeFamily,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: TextStyle(
      fontFamily: decorativeFamily,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: TextStyle(
      fontFamily: decorativeFamily,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontFamily: decorativeFamily,
      fontWeight: FontWeight.w600,
    ),

    // Titles / labels / body: main font
    titleLarge: TextStyle(fontFamily: family, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontFamily: family, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontFamily: family, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontFamily: family, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontFamily: family, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontFamily: family, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontFamily: family, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontFamily: family, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontFamily: family, fontWeight: FontWeight.w500),
  );

  static TextTheme light = base.apply(
    bodyColor: AppPalette.capeCodDark01,
    displayColor: AppPalette.blueRibbonDark04,
  );

  static TextTheme dark = base.apply(
    bodyColor: AppPalette.white,
    displayColor: AppPalette.blueRibbon,
  );
}
