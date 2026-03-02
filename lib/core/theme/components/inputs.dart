import 'package:flutter/material.dart';
import '../colors.dart';

class AppInputThemes {
  static const _sharpBorder = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: AppColors.lightGray, width: 2),
  );

  static const InputDecorationTheme light = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightGray,
    labelStyle: TextStyle(color: AppColors.blueRibbonDark04),
    border: _sharpBorder,
    enabledBorder: _sharpBorder,
    focusedBorder: _sharpBorder,
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.error, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.error, width: 2),
    ),
  );

  static const InputDecorationTheme dark = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.capeCodLight02,
    labelStyle: TextStyle(color: AppColors.capeCodDark01),
    border: _sharpBorder,
    enabledBorder: _sharpBorder,
    focusedBorder: _sharpBorder,
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.error, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.error, width: 2),
    ),
  );
}
