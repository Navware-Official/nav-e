import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/theme/typography.dart';

/// Shared visual frame for HUD widgets.
///
/// A 1px hairline rectangle with a small mono-uppercase title at the top,
/// an optional accent corner dot, and an inner content region. When
/// [accent] is true the frame fills with a translucent brand-blue tint
/// and uses the brand-blue border instead of `borderStrong`.
class WidgetFrame extends StatelessWidget {
  const WidgetFrame({
    super.key,
    required this.title,
    required this.child,
    this.accent = false,
    this.dense = false,
  });

  final String title;
  final Widget child;
  final bool accent;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final pad = dense ? 10.0 : 14.0; // off-grid (matches design's 10/14)
    final border = accent ? appColors.hiVis : appColors.borderStrong;
    final bg = accent
        ? appColors.hiVis.withValues(alpha: 0.08)
        : Colors.transparent;
    final titleColor = accent ? appColors.info : appColors.fgMuted;
    final dotColor = accent ? appColors.hiVis : appColors.fgMuted;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1),
      ),
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: AppTypography.eyebrow.copyWith(
                  fontSize: 9,
                  letterSpacing: 1.44, // ~0.16em at 9px
                  color: titleColor,
                ),
              ),
              Container(width: 4, height: 4, color: dotColor),
            ],
          ),
          const SizedBox(height: 6), // off-grid (mid-gap inside widget tile)
          DefaultTextStyle.merge(
            style: TextStyle(color: appColors.fgPrimary),
            child: child,
          ),
        ],
      ),
    );
  }
}
