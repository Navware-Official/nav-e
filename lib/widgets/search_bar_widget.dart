import 'package:flutter/material.dart';

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
    final textTheme = theme.textTheme;
    final fillColor = colorScheme.surfaceContainerHighest;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
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
          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hintText ?? 'Hinted search text',
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: colorScheme.onSurfaceVariant,
              size: 22,
            ),
            suffixIcon: onMenuTap != null
                ? IconButton(
                    icon: const Icon(Icons.menu, size: 24),
                    onPressed: onMenuTap,
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  )
                : null,
            filled: true,
            fillColor: fillColor,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide.none,
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
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
