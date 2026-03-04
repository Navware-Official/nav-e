import 'package:flutter/material.dart';

/// Theming for settings screen sections: bordered panels, sharp corners, no shadow.
/// Use [panelDecoration] and [sectionTitleStyle] for consistency.
class SettingsPanelStyle {
  SettingsPanelStyle._();

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

  /// Box decoration for a settings section panel: theme surface background,
  /// border, sharp corners, no shadow. Uses surface container for readability.
  static BoxDecoration panelDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.colorScheme.surfaceContainerLow,
      border: Border.all(
        color: theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
      borderRadius: BorderRadius.zero,
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
