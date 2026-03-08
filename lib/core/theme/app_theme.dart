import 'package:flutter/material.dart';
import 'colors.dart';
import 'palette.dart';
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
          seedColor: AppPalette.blueRibbon,
          primary: AppPalette.blueRibbon,
        ).copyWith(
          surface: AppPalette.white,
          onSurface: AppPalette.capeCodDark02,
          onSurfaceVariant: AppPalette.capeCodLight02,
          error: const Color(0xFFC62828),
          onError: AppPalette.white,
          primaryContainer: const Color(0xFFDDE3FF),
          onPrimaryContainer: AppPalette.blueRibbonDark04,
          secondaryContainer: const Color(0xFFE5E8FF),
          onSecondaryContainer: AppPalette.blueRibbonDark02,
          tertiaryContainer: const Color(0xFFECEEFF),
          onTertiaryContainer: AppPalette.blueRibbonDark04,
        );

    final sharpShape = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppPalette.white,
      colorScheme: colorScheme,
      appBarTheme: AppBarThemes.light,
      cardTheme: AppCardThemes.light,
      elevatedButtonTheme: AppButtonThemes.elevatedLight,
      outlinedButtonTheme: AppButtonThemes.outlinedLight,
      inputDecorationTheme: AppInputThemes.light,
      textTheme: AppTypography.light,
      iconTheme: const IconThemeData(color: AppPalette.blueRibbonDark04),
      dividerColor: AppPalette.lightGray,
      dialogTheme: DialogThemeData(shape: sharpShape),
      bottomSheetTheme: BottomSheetThemeData(shape: sharpShape),
      extensions: const [AppColors.light],
    );
  }

  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: AppPalette.blueRibbon,
          primary: AppPalette.blueRibbon,
        ).copyWith(
          surface: AppPalette.capeCodDark01,
          onSurface: AppPalette.white,
          onSurfaceVariant: AppPalette.lightGray,
          error: const Color(0xFFC62828),
          onError: AppPalette.white,
          primaryContainer: AppPalette.blueRibbonDark02,
          onPrimaryContainer: AppPalette.white,
          secondaryContainer: AppPalette.blueRibbonDark04,
          onSecondaryContainer: AppPalette.white,
          tertiaryContainer: const Color(0xFF1A2A7A),
          onTertiaryContainer: AppPalette.white,
        );

    final sharpShape = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppPalette.capeCodDark01,
      colorScheme: colorScheme,
      appBarTheme: AppBarThemes.dark,
      cardTheme: AppCardThemes.dark,
      elevatedButtonTheme: AppButtonThemes.elevatedDark,
      outlinedButtonTheme: AppButtonThemes.outlinedDark,
      inputDecorationTheme: AppInputThemes.dark,
      textTheme: AppTypography.dark,
      iconTheme: const IconThemeData(color: AppPalette.white),
      dividerColor: AppPalette.lightGray,
      dialogTheme: DialogThemeData(shape: sharpShape),
      bottomSheetTheme: BottomSheetThemeData(shape: sharpShape),
      extensions: const [AppColors.dark],
    );
  }
}
