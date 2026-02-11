import 'package:flutter/material.dart';

/// Shows a modal bottom sheet with information from a data layer feature
/// (e.g. parking: name, address, capacity, info).
void showDataLayerInfoBottomSheet(
  BuildContext context, {
  required String layerId,
  required Map<String, dynamic> properties,
}) {
  final theme = Theme.of(context);
  final title = properties['name']?.toString() ?? 'Details';
  final entries = <MapEntry<String, String>>[];
  final skipKeys = {'name'};
  for (final e in properties.entries) {
    if (skipKeys.contains(e.key)) continue;
    final key = e.key;
    final value = e.value;
    if (value != null && value.toString().trim().isNotEmpty) {
      final label = _labelForKey(key);
      entries.add(MapEntry(label, value.toString()));
    }
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (entries.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No additional information.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ...entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.value,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    ),
  );
}

String _labelForKey(String key) {
  switch (key.toLowerCase()) {
    case 'address':
      return 'Address';
    case 'capacity':
      return 'Capacity';
    case 'info':
    case 'description':
      return 'Info';
    default:
      if (key.isEmpty) return key;
      return key[0].toUpperCase() +
          key.substring(1).replaceAllMapped(
                RegExp(r'([A-Z])|_'),
                (m) => m.group(1) != null ? ' ${m.group(1)}' : ' ',
              );
  }
}
