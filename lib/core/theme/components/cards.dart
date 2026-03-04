import 'package:flutter/material.dart';
import '../colors.dart';

class AppCardThemes {
  static final CardThemeData light = CardThemeData(
    color: AppColors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    clipBehavior: Clip.antiAlias,
  );

  static final CardThemeData dark = CardThemeData(
    color: AppColors.capeCodLight02,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    clipBehavior: Clip.antiAlias,
  );
}
