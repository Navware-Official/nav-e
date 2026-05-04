import 'package:flutter/material.dart';
import '../colors.dart';

class AppDecorations {
  AppDecorations._();

  /// Panel/section container: theme surface background for readability,
  /// 1px hairline border, no rounded corners. Reads borderStrong from
  /// [AppColors] so it follows the active theme.
  static BoxDecoration panelDecoration(ThemeData theme, {Color? borderColor}) {
    final appColors = theme.extension<AppColors>()!;
    return BoxDecoration(
      color: theme.colorScheme.surface,
      border: Border.all(
        color: borderColor ?? appColors.borderStrong,
        width: 1,
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

  /// Accent panel — used for active/selected surfaces (active route card,
  /// turn card, selected widget tile in the editor).
  static BoxDecoration accentPanel(ThemeData theme) {
    final appColors = theme.extension<AppColors>()!;
    return BoxDecoration(
      // Translucent brand-blue tint over the underlying surface.
      color: appColors.hiVis.withValues(alpha: 0.08),
      border: Border.all(color: appColors.hiVis, width: 1),
      borderRadius: BorderRadius.zero,
    );
  }
}
