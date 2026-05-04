import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/theme/typography.dart';

/// Search bar in the Navware visual language: sharp 0px corners, 1px
/// hairline border, mono-uppercase placeholder. Sits over a translucent
/// dark fill so it remains legible above the map.
class SearchBarWidget extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String? hintText;

  /// When set, a burger menu icon is shown on the right and this is called on tap.
  final VoidCallback? onMenuTap;

  const SearchBarWidget({
    super.key,
    this.onChanged,
    this.onTap,
    this.hintText,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.extension<AppColors>()!;
    final textTheme = theme.textTheme;

    final isDark = theme.brightness == Brightness.dark;
    // The map sits behind the search bar; pin a translucent dark fill on
    // dark mode and a clean surface on light mode so contrast holds.
    final fillColor = isDark ? const Color(0xEB000000) : colorScheme.surface;
    final borderColor = appColors.borderStrong;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: fillColor,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: TextField(
          readOnly: onTap != null,
          onTap: onTap,
          onChanged: onChanged,
          style: textTheme.bodyMedium?.copyWith(color: appColors.fgPrimary),
          decoration: InputDecoration(
            hintText: hintText ?? 'Search for a place',
            hintStyle: TextStyle(
              fontFamily: AppTypography.monoFamily,
              fontSize: 14,
              letterSpacing: 0.56,
              color: appColors.fgMuted,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: appColors.fgSecondary,
              size: 18,
            ),
            suffixIcon: onMenuTap != null
                ? IconButton(
                    icon: const Icon(Icons.menu, size: 22),
                    onPressed: onMenuTap,
                    style: IconButton.styleFrom(
                      foregroundColor: appColors.fgPrimary,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  )
                : null,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }
}
