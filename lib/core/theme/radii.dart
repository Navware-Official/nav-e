import 'package:flutter/material.dart';

/// Corner radius constants. The Navware brand language is SHARP — default
/// is 0. Radii exist only for hit targets (pill buttons) and rare elevated
/// surfaces.
class AppRadii {
  AppRadii._();

  static const double r0 = 0;
  static const double r1 = 2;
  static const double r2 = 4;

  /// 8 px — rare; pill badges and a few elevated surfaces.
  static const double r3 = 8;

  static const double rPill = 999;

  static const Radius radius0 = Radius.zero;
  static const Radius radius1 = Radius.circular(r1);
  static const Radius radius2 = Radius.circular(r2);
  static const Radius radius3 = Radius.circular(r3);

  static const BorderRadius all0 = BorderRadius.zero;
  static const BorderRadius all1 = BorderRadius.all(radius1);
  static const BorderRadius all2 = BorderRadius.all(radius2);
  static const BorderRadius all3 = BorderRadius.all(radius3);
}
