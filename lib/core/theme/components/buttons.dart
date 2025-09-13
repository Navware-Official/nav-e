import 'package:flutter/material.dart';
import '../colors.dart';

class AppButtonThemes {
  static ElevatedButtonThemeData elevatedLight = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.blueRibbon,
      foregroundColor: AppColors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );

  static ElevatedButtonThemeData elevatedDark = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.lightGray,
      foregroundColor: AppColors.blueRibbon,
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );

  static OutlinedButtonThemeData outlinedLight = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppColors.blueRibbon, width: 2),
      foregroundColor: AppColors.blueRibbonDark02,
    ),
  );

  static OutlinedButtonThemeData outlinedDark = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppColors.blueRibbon, width: 2),
      foregroundColor: AppColors.blueRibbon,
    ),
  );
}
