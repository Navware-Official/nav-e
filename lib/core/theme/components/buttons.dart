import 'package:flutter/material.dart';
import '../palette.dart';

/// Button themes — sharp 0px corners, flat fills, hairline borders.
class AppButtonThemes {
  AppButtonThemes._();

  static const _sharpShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
  );

  static ElevatedButtonThemeData elevatedLight = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppPalette.brandBlue,
      foregroundColor: AppPalette.brandWhite,
      disabledBackgroundColor: AppPalette.paper300,
      disabledForegroundColor: AppPalette.brandGray,
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
      shape: _sharpShape,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  static ElevatedButtonThemeData elevatedDark = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppPalette.brandBlue,
      foregroundColor: AppPalette.brandWhite,
      disabledBackgroundColor: AppPalette.ink300,
      disabledForegroundColor: AppPalette.ink600,
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
      shape: _sharpShape,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  static OutlinedButtonThemeData outlinedLight = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppPalette.brandGray, width: 1),
      foregroundColor: AppPalette.brandBlue,
      backgroundColor: Colors.transparent,
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
      shape: _sharpShape,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  static OutlinedButtonThemeData outlinedDark = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppPalette.ink500, width: 1),
      foregroundColor: AppPalette.brandWhite,
      backgroundColor: Colors.transparent,
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
      shape: _sharpShape,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
