import 'package:flutter/material.dart';
import '../palette.dart';

class AppInputThemes {
  static const _sharpBorder = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: AppPalette.lightGray, width: 2),
  );

  static const _errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: Color(0xFFC62828), width: 2),
  );

  static const InputDecorationTheme light = InputDecorationTheme(
    filled: true,
    fillColor: AppPalette.lightGray,
    labelStyle: TextStyle(color: AppPalette.blueRibbonDark04),
    border: _sharpBorder,
    enabledBorder: _sharpBorder,
    focusedBorder: _sharpBorder,
    errorBorder: _errorBorder,
    focusedErrorBorder: _errorBorder,
  );

  static const InputDecorationTheme dark = InputDecorationTheme(
    filled: true,
    fillColor: AppPalette.capeCodLight02,
    labelStyle: TextStyle(color: AppPalette.capeCodDark01),
    border: _sharpBorder,
    enabledBorder: _sharpBorder,
    focusedBorder: _sharpBorder,
    errorBorder: _errorBorder,
    focusedErrorBorder: _errorBorder,
  );
}
