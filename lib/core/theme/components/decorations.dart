import 'package:flutter/material.dart';
import '../palette.dart';

class AppDecorations {
  /// Panel/section container: theme surface background for readability,
  /// sharp border, no rounded corners.
  static BoxDecoration panelDecoration(ThemeData theme, {Color? borderColor}) {
    return BoxDecoration(
      color: theme.colorScheme.surfaceContainerLow,
      border: Border.all(
        color: borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.5),
        width: 2,
      ),
      borderRadius: BorderRadius.zero,
    );
  }

  /// Generic card-like container: same as [panelDecoration] for readability.
  static BoxDecoration cardLikeDecoration(
    ThemeData theme, {
    Color? borderColor,
  }) {
    return panelDecoration(theme, borderColor: borderColor);
  }
}
