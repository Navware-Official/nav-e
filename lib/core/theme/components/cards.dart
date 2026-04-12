import 'package:flutter/material.dart';
import '../palette.dart';

class AppCardThemes {
  static final CardThemeData light = CardThemeData(
    color: AppPalette.white,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      side: BorderSide(width: 1, color: AppPalette.lightGray),
    ),
  );

  static final CardThemeData dark = CardThemeData(
    color: AppPalette.capeCodDark01,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      side: BorderSide(
        width: 1,
        color: AppPalette.lightGray.withValues(alpha: 0.25),
      ),
    ),
  );
}
