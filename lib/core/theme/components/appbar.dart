import 'package:flutter/material.dart';
import '../colors.dart';

class AppBarThemes {
  static const AppBarTheme light = AppBarTheme(
    backgroundColor: AppColors.capeCodDark01,
    foregroundColor: AppColors.white,
    elevation: 0,
  );

  static const AppBarTheme dark = AppBarTheme(
    backgroundColor: AppColors.blueRibbonDark04,
    foregroundColor: AppColors.capeCodDark01,
    elevation: 0,
  );
}
