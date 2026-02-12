import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/colors.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final fillColor = colorScheme.surfaceContainerHighest; // light grey bar
    const borderRadius = 24.0;

    final borderRadiusValue = BorderRadius.circular(borderRadius);
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadiusValue,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: TextField(
        readOnly: onTap != null,
        onTap: onTap,
        onChanged: onChanged,
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hintText ?? 'Hinted search text',
          hintStyle: TextStyle(
            color: AppColors.capeCodLight02,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.capeCodDark02,
            size: 22,
          ),
          suffixIcon: onMenuTap != null
              ? IconButton(
                  icon: const Icon(Icons.menu, size: 24),
                  onPressed: onMenuTap,
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.capeCodDark02,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                )
              : null,
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: borderRadiusValue,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadiusValue,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadiusValue,
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      ),
    );
  }
}

