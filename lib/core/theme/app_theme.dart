import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';
import 'components/appbar.dart';
import 'components/buttons.dart';
import 'components/cards.dart';
import 'components/inputs.dart';

class AppTheme {
  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: AppColors.blueRibbon,
          primary: AppColors.blueRibbon,
        ).copyWith(
          surface: AppColors.white,
          onSurface: AppColors.capeCodDark02,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          error: AppColors.error,
          onError: AppColors.white,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: colorScheme,
    );

    return base.copyWith(
      appBarTheme: AppBarThemes.light,
      cardTheme: AppCardThemes.light,
      elevatedButtonTheme: AppButtonThemes.elevatedLight,
      outlinedButtonTheme: AppButtonThemes.outlinedLight,
      inputDecorationTheme: AppInputThemes.light,
      textTheme: AppTypography.light,
      iconTheme: const IconThemeData(color: AppColors.blueRibbonDark04),
      dividerColor: AppColors.lightGray,
    );
  }

  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: AppColors.blueRibbon,
          primary: AppColors.blueRibbon,
        ).copyWith(
          surface: AppColors.capeCodDark01,
          onSurface: AppColors.white,
          onSurfaceVariant: AppColors.lightGray,
          error: AppColors.error,
          onError: AppColors.white,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.capeCodDark01,
      colorScheme: colorScheme,
    );

    return base.copyWith(
      appBarTheme: AppBarThemes.dark,
      cardTheme: AppCardThemes.dark,
      elevatedButtonTheme: AppButtonThemes.elevatedDark,
      outlinedButtonTheme: AppButtonThemes.outlinedDark,
      inputDecorationTheme: AppInputThemes.dark,
      textTheme: AppTypography.dark,
      iconTheme: const IconThemeData(color: AppColors.white),
      dividerColor: AppColors.lightGray,
    );
  }
}
