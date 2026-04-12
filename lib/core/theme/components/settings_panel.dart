import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/spacing.dart';

/// Theming for settings screen sections: bordered panels, sharp corners, no shadow.
/// Use [panelDecoration] and [sectionTitleStyle] for consistency.
class SettingsPanelStyle {
  SettingsPanelStyle._();

  /// Horizontal margin around section panels.
  static const double sectionHorizontalMargin = AppSpacing.md;

  /// Padding for the section header label above each panel.
  static const EdgeInsets sectionHeaderPadding = EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.lg,
    AppSpacing.md,
    AppSpacing.sm,
  );

  /// Inner padding for panel content (e.g. first block of content).
  static const EdgeInsets panelContentPadding = EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.md,
    AppSpacing.md,
    AppSpacing.sm,
  );

  /// Box decoration for a settings section panel: theme surface background,
  /// outlineVariant border, sharp corners, no shadow.
  static BoxDecoration panelDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.colorScheme.surfaceContainerLow,
      border: Border.all(color: theme.colorScheme.outlineVariant),
    );
  }

  /// Text style for the section title (e.g. "Theme", "Maps", "About").
  static TextStyle sectionTitleStyle(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontSize: 16, // off-grid
      fontWeight: FontWeight.w600,
    );
  }
}
