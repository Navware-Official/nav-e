import 'package:flutter/material.dart';

/// Elevation / shadow scale.
///
/// Pass [colorScheme.shadow] as the [shadow] argument so the shadow colour
/// adapts to light/dark mode automatically.
///
/// Usage:
/// ```dart
/// BoxDecoration(boxShadow: [AppElevation.level2(colorScheme.shadow)])
/// ```
class AppElevation {
  AppElevation._();

  static BoxShadow level1(Color shadow) => BoxShadow(
    color: shadow.withValues(alpha: 0.08),
    blurRadius: 2,
    offset: const Offset(0, 1),
  );

  static BoxShadow level2(Color shadow) => BoxShadow(
    color: shadow.withValues(alpha: 0.12),
    blurRadius: 6,
    offset: const Offset(0, 2),
  );

  static BoxShadow level3(Color shadow) => BoxShadow(
    color: shadow.withValues(alpha: 0.16),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  static BoxShadow level4(Color shadow) => BoxShadow(
    color: shadow.withValues(alpha: 0.24),
    blurRadius: 20,
    offset: const Offset(0, 6),
  );
}
