import 'package:flutter/material.dart';

/// Raw colour palette — primitive hex values only.
///
/// Use this in theme construction (app_theme.dart, components/) and
/// low-level infrastructure code (map layers, protobuf colour args).
///
/// Do NOT import this in widget build methods. Widgets should read semantic
/// tokens from colorScheme or Theme.of(context).extension[AppColors]().
class AppPalette {
  AppPalette._();

  static const Color blueRibbon = Color(0xFF375AF9);
  static const Color blueRibbonDark02 = Color(0xFF0121D1);
  static const Color blueRibbonDark04 = Color(0xFF01216C);

  static const Color white = Color(0xFFFBFFFF);
  static const Color lightGray = Color(0xFFD0D2D3);
  static const Color capeCodLight02 = Color(0xFF6F7070);
  static const Color capeCodDark01 = Color(0xFF343535);
  static const Color capeCodDark02 = Color(0xFF181818);
}
