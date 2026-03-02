import 'package:flutter/material.dart';
import '../colors.dart';

class AppDecorations {
  static final BoxDecoration userLocationMarker = BoxDecoration(
    shape: BoxShape.circle,
    color: AppColors.white,
    border: Border.all(color: AppColors.blueRibbonDark02, width: 2),
    boxShadow: const [
      BoxShadow(
        color: AppColors.blueRibbonDark02,
        blurRadius: 12,
        spreadRadius: 2,
        offset: Offset(0, 1),
      ),
    ],
  );

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
