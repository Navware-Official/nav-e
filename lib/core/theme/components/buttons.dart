import 'package:flutter/material.dart';
import '../colors.dart';
import '../styles/corner_block_border.dart';

class AppButtonThemes {
  static ElevatedButtonThemeData elevatedLight = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.blueRibbon,
      foregroundColor: AppColors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
      shape: const CornerBlockBorder(
        side: BorderSide(width: 1.4, color: Colors.black),
        blockOvershoot: 2,
      ),
    ),
  );

  static ElevatedButtonThemeData elevatedDark = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.lightGray,
      foregroundColor: AppColors.blueRibbon,
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
      shape: const CornerBlockBorder(
        side: BorderSide(width: 1.4, color: Colors.black),
        blockOvershoot: 2,
      ),
    ),
  );

  static OutlinedButtonThemeData outlinedLight = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppColors.blueRibbon, width: 2),
      foregroundColor: AppColors.blueRibbonDark02,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  static OutlinedButtonThemeData outlinedDark = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppColors.blueRibbon, width: 2),
      foregroundColor: AppColors.blueRibbon,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
