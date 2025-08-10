import 'package:flutter/material.dart';
import '../colors.dart';

class AppInputThemes {
  static const InputDecorationTheme light = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightGray,
    labelStyle: TextStyle(color: AppColors.blueRibbonDark04),
  );

  static const InputDecorationTheme dark = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.capeCodLight02,
    labelStyle: TextStyle(color: AppColors.capeCodDark01),
  );
}
