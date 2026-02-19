import 'package:flutter/material.dart';

/// Theming for settings screen sections: bordered panels with rounded corners,
/// no shadow. Use [panelDecoration] and [sectionTitleStyle] for consistency.
class SettingsPanelStyle {
  SettingsPanelStyle._();

  /// Border radius for section panels.
  static const double sectionRadius = 12.0;

  /// Horizontal margin around section panels.
  static const double sectionHorizontalMargin = 16.0;

  /// Padding for the section header label above each panel.
  static const EdgeInsets sectionHeaderPadding = EdgeInsets.fromLTRB(
    16,
    24,
    16,
    8,
  );

  /// Inner padding for panel content (e.g. first block of content).
  static const EdgeInsets panelContentPadding = EdgeInsets.fromLTRB(
    16,
    16,
    16,
    8,
  );

  /// Box decoration for a settings section panel: border, rounded corners, no shadow.
  static BoxDecoration panelDecoration(ThemeData theme) {
    return BoxDecoration(
      border: Border.all(
        color: theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
      borderRadius: BorderRadius.circular(sectionRadius),
    );
  }

  /// Text style for the section title (e.g. "Theme", "Maps", "About").
  static TextStyle sectionTitleStyle(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
  }
}
