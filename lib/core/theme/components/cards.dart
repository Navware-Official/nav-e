import 'package:flutter/material.dart';
import '../palette.dart';

/// Card themes — flat, sharp corners, 1px hairline border.
///
/// The design system is explicit: "Navware is flat — shadows are reserved
/// for the MAP layer to float above the grid." Don't add soft drop shadows.
class AppCardThemes {
  AppCardThemes._();

  static final CardThemeData light = CardThemeData(
    color: AppPalette.paper000,
    elevation: 0,
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      side: BorderSide(width: 1, color: AppPalette.brandGray),
      borderRadius: BorderRadius.zero,
    ),
  );

  static final CardThemeData dark = CardThemeData(
    color: AppPalette.ink300,
    elevation: 0,
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      side: BorderSide(width: 1, color: AppPalette.ink400),
      borderRadius: BorderRadius.zero,
    ),
  );
}
