import 'package:flutter/material.dart';
import 'colors.dart';
import 'palette.dart';
import 'typography.dart';
import 'components/appbar.dart';
import 'components/badges.dart';
import 'components/buttons.dart';
import 'components/cards.dart';
import 'components/inputs.dart';

/// App theme builder.
///
/// The Navware brand language is sharp (radius 0 by default) and flat
/// (no soft shadows — shadows are reserved for the map layer floating
/// above the grid). Both light and dark modes are first-class.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: AppPalette.brandBlue,
          primary: AppPalette.brandBlue,
        ).copyWith(
          surface: AppPalette.paper000,
          surfaceContainerLowest: AppPalette.paper000,
          surfaceContainerLow: AppPalette.paper100,
          surfaceContainer: AppPalette.paper100,
          surfaceContainerHigh: AppPalette.paper200,
          surfaceContainerHighest: AppPalette.paper200,
          onSurface: AppPalette.brandCharcoal,
          onSurfaceVariant: AppPalette.brandGray,
          outline: AppPalette.brandGray,
          outlineVariant: AppPalette.paper300,
          error: AppPalette.alert,
          onError: AppPalette.brandWhite,
          primaryContainer: const Color(0xFFDDE3FF),
          onPrimaryContainer: AppPalette.brandBlueDeep,
          secondary: AppPalette.brandBlueMid,
          onSecondary: AppPalette.brandWhite,
          secondaryContainer: const Color(0xFFE5E8FF),
          onSecondaryContainer: AppPalette.brandBlueDeep,
          tertiary: AppPalette.brandBlueDeep,
          tertiaryContainer: const Color(0xFFECEEFF),
          onTertiaryContainer: AppPalette.brandBlueDeep,
          shadow: AppPalette.brandBlack,
        );

    const sharpShape = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppPalette.paper100,
      colorScheme: colorScheme,
      appBarTheme: AppBarThemes.light,
      cardTheme: AppCardThemes.light,
      elevatedButtonTheme: AppButtonThemes.elevatedLight,
      outlinedButtonTheme: AppButtonThemes.outlinedLight,
      inputDecorationTheme: AppInputThemes.light,
      badgeTheme: AppBadgeThemes.light(),
      textTheme: AppTypography.light,
      iconTheme: const IconThemeData(color: AppPalette.brandCharcoal),
      dividerColor: AppPalette.paper300,
      dividerTheme: const DividerThemeData(
        color: AppPalette.paper300,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: const DialogThemeData(shape: sharpShape),
      bottomSheetTheme: const BottomSheetThemeData(shape: sharpShape),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppPalette.paper000,
        selectedItemColor: AppPalette.brandBlue,
        unselectedItemColor: AppPalette.brandGray,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppPalette.brandGray,
        textColor: AppPalette.brandCharcoal,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      extensions: const [AppColors.light],
    );
  }

  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: AppPalette.brandBlue,
          primary: AppPalette.brandBlue,
        ).copyWith(
          surface: AppPalette.ink100,
          surfaceContainerLowest: AppPalette.ink050,
          surfaceContainerLow: AppPalette.ink100,
          surfaceContainer: AppPalette.ink200,
          surfaceContainerHigh: AppPalette.ink300,
          surfaceContainerHighest: AppPalette.ink400,
          onSurface: AppPalette.ink999,
          onSurfaceVariant: AppPalette.ink800,
          outline: AppPalette.ink500,
          outlineVariant: AppPalette.ink400,
          error: AppPalette.alert,
          onError: AppPalette.brandWhite,
          primaryContainer: AppPalette.brandBlueDeep,
          onPrimaryContainer: AppPalette.brandWhite,
          secondary: AppPalette.brandBlueMid,
          onSecondary: AppPalette.brandWhite,
          secondaryContainer: AppPalette.brandBlueDeep,
          onSecondaryContainer: AppPalette.brandWhite,
          tertiary: AppPalette.brandBlueMid,
          tertiaryContainer: const Color(0xFF1A2A7A),
          onTertiaryContainer: AppPalette.brandWhite,
          shadow: AppPalette.brandBlack,
        );

    const sharpShape = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppPalette.ink050,
      colorScheme: colorScheme,
      appBarTheme: AppBarThemes.dark,
      cardTheme: AppCardThemes.dark,
      elevatedButtonTheme: AppButtonThemes.elevatedDark,
      outlinedButtonTheme: AppButtonThemes.outlinedDark,
      inputDecorationTheme: AppInputThemes.dark,
      badgeTheme: AppBadgeThemes.dark(),
      textTheme: AppTypography.dark,
      iconTheme: const IconThemeData(color: AppPalette.ink800),
      dividerColor: AppPalette.ink400,
      dividerTheme: const DividerThemeData(
        color: AppPalette.ink400,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: const DialogThemeData(shape: sharpShape),
      bottomSheetTheme: const BottomSheetThemeData(shape: sharpShape),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppPalette.ink050,
        selectedItemColor: AppPalette.brandBlue,
        unselectedItemColor: AppPalette.ink600,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppPalette.ink700,
        textColor: AppPalette.ink999,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      extensions: const [AppColors.dark],
    );
  }
}
