import 'package:flutter/material.dart';
import '../palette.dart';
import '../styles/corner_block_border.dart';

class AppCardThemes {
  static final CardThemeData light = CardThemeData(
    color: AppPalette.white,
    clipBehavior: Clip.none,
    shape: const CornerBlockBorder(
      side: BorderSide(width: 2, color: AppPalette.lightGray),
      blockOvershoot: 2,
      blockFillColor: AppPalette.lightGray,
    ),
  );

  static final CardThemeData dark = CardThemeData(
    color: AppPalette.capeCodLight02,
    clipBehavior: Clip.none,
    shape: const CornerBlockBorder(
      side: BorderSide(width: 2, color: AppPalette.capeCodDark01),
      blockOvershoot: 2,
      blockFillColor: AppPalette.capeCodDark01,
    ),
  );
}
