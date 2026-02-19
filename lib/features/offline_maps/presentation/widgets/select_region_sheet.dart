import 'package:flutter/material.dart';

import 'package:nav_e/features/offline_maps/data/predefined_regions.dart';

/// Shows a bottom sheet with predefined regions + "Custom (enter bounds)".
/// Returns [PredefinedRegion] when a predefined item is tapped (caller gets
/// bbox + name), or null when "Custom" is tapped.
Future<PredefinedRegion?> showSelectRegionSheetResult(BuildContext context) {
  return showModalBottomSheet<PredefinedRegion?>(
    context: context,
    builder: (context) => const _SelectRegionSheet(),
  );
}

class _SelectRegionSheet extends StatelessWidget {
  const _SelectRegionSheet();

  static String _bboxSubtitle(PredefinedRegion r) {
    return '${r.south.toStringAsFixed(1)}°N–${r.north.toStringAsFixed(1)}°N, '
        '${r.west.toStringAsFixed(1)}°E–${r.east.toStringAsFixed(1)}°E';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Select region',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final region in predefinedRegions)
                  ListTile(
                    title: Text(region.name),
                    subtitle: Text(_bboxSubtitle(region)),
                    onTap: () => Navigator.of(context).pop(region),
                  ),
                const Divider(),
                ListTile(
                  title: const Text('Custom (enter bounds)'),
                  subtitle: const Text(
                    'Enter north, south, east, west manually',
                  ),
                  onTap: () =>
                      Navigator.of(context).pop<PredefinedRegion?>(null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
