import 'package:flutter/material.dart';
import '../palette.dart';
import '../styles/corner_block_border.dart';

class AppButtonThemes {
  static ElevatedButtonThemeData elevatedLight = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppPalette.blueRibbon,
      foregroundColor: AppPalette.white,
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
      shape: const CornerBlockBorder(
        side: BorderSide(width: 2, color: AppPalette.blueRibbonDark02),
        blockOvershoot: 2,
        blockFillColor: AppPalette.blueRibbon,
      ),
    ),
  );

  static ElevatedButtonThemeData elevatedDark = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppPalette.lightGray,
      foregroundColor: AppPalette.blueRibbon,
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
      shape: const CornerBlockBorder(
        side: BorderSide(width: 2, color: AppPalette.capeCodDark01),
        blockOvershoot: 2,
        blockFillColor: AppPalette.lightGray,
      ),
    ),
  );

  static OutlinedButtonThemeData outlinedLight = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppPalette.blueRibbon, width: 2),
      foregroundColor: AppPalette.blueRibbonDark02,
      shape: const CornerBlockBorder(
        side: BorderSide(color: AppPalette.blueRibbon, width: 2),
        blockOvershoot: 2,
        blockFillColor: AppPalette.white,
      ),
    ),
  );

  static OutlinedButtonThemeData outlinedDark = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppPalette.blueRibbon, width: 2),
      foregroundColor: AppPalette.blueRibbon,
      shape: const CornerBlockBorder(
        side: BorderSide(color: AppPalette.blueRibbon, width: 2),
        blockOvershoot: 2,
        blockFillColor: AppPalette.capeCodDark01,
      ),
    ),
  );
}
