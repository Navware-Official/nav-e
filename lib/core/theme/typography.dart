import 'package:flutter/material.dart';
import 'colors.dart';

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
    displayLarge: const TextStyle(
      fontFamily: decorativeFamily,
      fontWeight: FontWeight.w800,
    ),
    displayMedium: const TextStyle(
      fontFamily: decorativeFamily,
      fontWeight: FontWeight.w700,
    ),
    displaySmall: const TextStyle(
      fontFamily: decorativeFamily,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: const TextStyle(
      fontFamily: decorativeFamily,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: const TextStyle(
      fontFamily: decorativeFamily,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: const TextStyle(
      fontFamily: decorativeFamily,
      fontWeight: FontWeight.w600,
    ),

    // Titles / labels / body: main font
    titleLarge: const TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: const TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: const TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: const TextStyle(fontFamily: family, fontWeight: FontWeight.w400),
    bodyMedium: const TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: const TextStyle(fontFamily: family, fontWeight: FontWeight.w400),
    labelLarge: const TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: const TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: const TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w500,
    ),
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
