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

  // ─── Navware brand palette ─────────────────────────────────────────────
  // Confirmed brand colours. `brand*` are the canonical names that match
  // the design system tokens; the legacy aliases below preserve existing
  // call sites.

  static const Color brandBlue = Color(0xFF0121D1); // primary · deep electric
  static const Color brandBlueMid = Color(0xFF375AF9); // hover · interactive
  static const Color brandBlueDeep = Color(0xFF01216C); // pressed · selected
  static const Color brandWhite = Color(0xFFFBFFFF);
  static const Color brandSilver = Color(0xFFD0D2D3);
  static const Color brandGray = Color(0xFF6F7070);
  static const Color brandCharcoal = Color(0xFF343535);
  static const Color brandBlack = Color(0xFF000000);

  // Legacy aliases — kept for existing call sites (map markers, route
  // colour args, etc). New code should prefer the brand* names above.
  static const Color blueRibbon = brandBlueMid; // #375AF9
  static const Color blueRibbonDark02 = brandBlue; // #0121D1
  static const Color blueRibbonDark04 = brandBlueDeep; // #01216C
  static const Color white = brandWhite;
  static const Color lightGray = brandSilver;
  static const Color capeCodLight02 = brandGray;
  static const Color capeCodDark01 = brandCharcoal;
  static const Color capeCodDark02 = Color(0xFF181818);

  // ─── Ink ramp (dark ground) ────────────────────────────────────────────
  static const Color ink000 = brandBlack;
  static const Color ink050 = Color(0xFF0A0B0C); // page ground
  static const Color ink100 = Color(0xFF141516); // surface base
  static const Color ink200 = Color(0xFF1E1F20); // raised surface
  static const Color ink300 = Color(0xFF2A2B2C); // card
  static const Color ink400 = brandCharcoal; // border-strong
  static const Color ink500 = Color(0xFF4A4B4C); // border
  static const Color ink600 = brandGray; // muted fg
  static const Color ink700 = Color(0xFF8E9091); // secondary fg
  static const Color ink800 = Color(0xFFB0B2B3); // primary fg alt
  static const Color ink900 = brandSilver; // high-emphasis fg
  static const Color ink999 = brandWhite; // pure fg

  // ─── Paper ramp (light ground) ─────────────────────────────────────────
  static const Color paper000 = brandWhite;
  static const Color paper100 = Color(0xFFF4F6F7); // warm-off
  static const Color paper200 = Color(0xFFE6E9EA);
  static const Color paper300 = brandSilver;
  static const Color paper400 = Color(0xFFA9ABAC);

  // ─── Signal palette (functional state) ────────────────────────────────
  // Derived, not brand confirmed. Kept muted so they don't fight blue.
  static const Color amber = Color(0xFFE89B00); // warning · caution
  static const Color amberDeep = Color(0xFFA36D00);
  static const Color signal = Color(0xFF1FAA55); // success · GPS lock
  static const Color signalDeep = Color(0xFF0E7A3C);
  static const Color alert = Color(0xFFD72638); // error · off-route
  static const Color alertDeep = Color(0xFF9E1A29);

  // ─── Map / grid lines ─────────────────────────────────────────────────
  static const Color gridLineDark = Color(0xFF1C1E20);
  static const Color gridLineStrongDark = Color(0xFF262A2D);
  static const Color gridLineLight = Color(0xFFE4E6E7);
  static const Color gridLineStrongLight = Color(0xFFD4D6D7);
}
