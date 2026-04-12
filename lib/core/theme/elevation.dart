import 'package:flutter/material.dart';

/// Shadow lists for four semantic elevation levels.
///
/// Usage:
///   BoxDecoration(boxShadow: AppElevation.level2(colorScheme.shadow))
class AppElevation {
  AppElevation._();

  /// Level 1 — subtle; tightly-inset cards and chips.
  static List<BoxShadow> level1(Color shadow) => [
    BoxShadow(
      color: shadow.withValues(alpha: 0.06),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: shadow.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Level 2 — default; standard cards and panels.
  static List<BoxShadow> level2(Color shadow) => [
    BoxShadow(
      color: shadow.withValues(alpha: 0.10),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: shadow.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Level 3 — raised; floating panels and bottom sheets.
  static List<BoxShadow> level3(Color shadow) => [
    BoxShadow(
      color: shadow.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: shadow.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Level 4 — modal; dialogs and full-screen overlays.
  static List<BoxShadow> level4(Color shadow) => [
    BoxShadow(
      color: shadow.withValues(alpha: 0.20),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: shadow.withValues(alpha: 0.12),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];
}
