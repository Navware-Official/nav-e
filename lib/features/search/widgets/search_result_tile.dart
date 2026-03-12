import 'package:flutter/material.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';

class SearchResultTile extends StatelessWidget {
  final GeocodingResult result;
  final ValueChanged<GeocodingResult>? onSelected;

  const SearchResultTile({super.key, required this.result, this.onSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        FocusScope.of(context).unfocus();
        onSelected?.call(result);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        color: colorScheme.secondaryContainer,
        child: Row(
          children: [
            Icon(
              Icons.place,
              size: 20,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (result.type.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      result.type,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
