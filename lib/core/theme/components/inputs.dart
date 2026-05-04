import 'package:flutter/material.dart';
import '../palette.dart';
import '../typography.dart';

/// Input themes — sharp 0px corners, 1px hairline border.
class AppInputThemes {
  AppInputThemes._();

  static const _lightBorder = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: AppPalette.brandGray, width: 1),
  );

  static const _lightFocusBorder = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: AppPalette.brandBlueMid, width: 1),
  );

  static const _darkBorder = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: AppPalette.ink500, width: 1),
  );

  static const _darkFocusBorder = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: AppPalette.brandBlueMid, width: 1),
  );

  static const _errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: AppPalette.alert, width: 1),
  );

  static const _hintMono = TextStyle(
    fontFamily: AppTypography.monoFamily,
    fontSize: 14,
    letterSpacing: 0.56,
    fontWeight: FontWeight.w500,
  );

  static const InputDecorationTheme light = InputDecorationTheme(
    filled: true,
    fillColor: AppPalette.paper000,
    labelStyle: TextStyle(color: AppPalette.brandGray),
    hintStyle: TextStyle(
      color: AppPalette.brandGray,
      fontFamily: AppTypography.monoFamily,
      letterSpacing: 0.56,
    ),
    border: _lightBorder,
    enabledBorder: _lightBorder,
    focusedBorder: _lightFocusBorder,
    errorBorder: _errorBorder,
    focusedErrorBorder: _errorBorder,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  static const InputDecorationTheme dark = InputDecorationTheme(
    filled: true,
    fillColor: AppPalette.ink100,
    labelStyle: TextStyle(color: AppPalette.ink600),
    hintStyle: TextStyle(
      color: AppPalette.ink600,
      fontFamily: AppTypography.monoFamily,
      letterSpacing: 0.56,
    ),
    border: _darkBorder,
    enabledBorder: _darkBorder,
    focusedBorder: _darkFocusBorder,
    errorBorder: _errorBorder,
    focusedErrorBorder: _errorBorder,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  /// Exposed for callers that want to mirror the placeholder mono treatment
  /// in custom widgets that don't use [InputDecoration] directly.
  static const TextStyle hintMono = _hintMono;
}
