import 'package:flutter/material.dart';

import 'package:nav_e/core/domain/entities/offline_region.dart';

class OfflineRegionListTile extends StatelessWidget {
  const OfflineRegionListTile({
    super.key,
    required this.region,
    required this.onDelete,
    this.onSendToDevice,
  });

  final OfflineRegion region;
  final VoidCallback onDelete;
  final VoidCallback? onSendToDevice;

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(region.name),
      subtitle: Text(
        '${region.north.toStringAsFixed(2)}°N – ${region.south.toStringAsFixed(2)}°S, '
        '${region.west.toStringAsFixed(2)}°W – ${region.east.toStringAsFixed(2)}°E · '
        '${_formatBytes(region.sizeBytes)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onSendToDevice != null)
            IconButton(
              icon: const Icon(Icons.send_outlined),
              onPressed: onSendToDevice,
              tooltip: 'Send to device',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
