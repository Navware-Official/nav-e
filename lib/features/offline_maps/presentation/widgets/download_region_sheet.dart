import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nav_e/features/offline_maps/data/predefined_regions.dart';
import 'package:nav_e/features/offline_maps/cubit/offline_maps_cubit.dart';
import 'package:nav_e/features/offline_maps/cubit/offline_maps_state.dart';

/// Bottom sheet: name + bbox (n/s/e/w) + zoom range, then start download with progress.
/// When [initialBbox] is set (e.g. from map selection), bounds are pre-filled and
/// shown in a collapsed section so the user can focus on name and zoom.
class DownloadRegionSheet extends StatefulWidget {
  const DownloadRegionSheet({super.key, this.initialBbox, this.initialName});

  final SelectedRegionBbox? initialBbox;
  final String? initialName;

  @override
  State<DownloadRegionSheet> createState() => _DownloadRegionSheetState();
}

class _DownloadRegionSheetState extends State<DownloadRegionSheet> {
  final _nameController = TextEditingController(text: 'My region');
  final _northController = TextEditingController(text: '52.5');
  final _southController = TextEditingController(text: '52.3');
  final _eastController = TextEditingController(text: '5.0');
  final _westController = TextEditingController(text: '4.7');
  final _minZoomController = TextEditingController(text: '0');
  final _maxZoomController = TextEditingController(text: '12');

  @override
  void initState() {
    super.initState();
    final bbox = widget.initialBbox;
    if (bbox != null) {
      _northController.text = bbox.north.toStringAsFixed(5);
      _southController.text = bbox.south.toStringAsFixed(5);
      _eastController.text = bbox.east.toStringAsFixed(5);
      _westController.text = bbox.west.toStringAsFixed(5);
    }
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _nameController.text = widget.initialName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _northController.dispose();
    _southController.dispose();
    _eastController.dispose();
    _westController.dispose();
    _minZoomController.dispose();
    _maxZoomController.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    final v = double.tryParse(s.trim());
    return v;
  }

  int? _parseInt(String s) {
    final v = int.tryParse(s.trim());
    return v;
  }

  Widget _buildBboxSection(bool isDownloading) {
    final hasInitialBbox = widget.initialBbox != null;
    final bboxFields = [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _northController,
              decoration: const InputDecoration(
                labelText: 'North',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !isDownloading,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _southController,
              decoration: const InputDecoration(
                labelText: 'South',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !isDownloading,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _westController,
              decoration: const InputDecoration(
                labelText: 'West',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !isDownloading,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _eastController,
              decoration: const InputDecoration(
                labelText: 'East',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !isDownloading,
            ),
          ),
        ],
      ),
    ];
    if (hasInitialBbox) {
      return ExpansionTile(
        initiallyExpanded: false,
        title: const Text('Region bounds (from map)'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: bboxFields,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: bboxFields,
    );
  }

  Future<void> _startDownload(BuildContext context) async {
    final north = _parseDouble(_northController.text);
    final south = _parseDouble(_southController.text);
    final east = _parseDouble(_eastController.text);
    final west = _parseDouble(_westController.text);
    final minZ = _parseInt(_minZoomController.text);
    final maxZ = _parseInt(_maxZoomController.text);
    final name = _nameController.text.trim();
    if (name.isEmpty ||
        north == null ||
        south == null ||
        east == null ||
        west == null ||
        minZ == null ||
        maxZ == null ||
        north <= south ||
        east <= west ||
        minZ < 0 ||
        maxZ > 18 ||
        minZ > maxZ) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid values: check name, bbox (N>S, E>W), and zoom (0–18, min ≤ max)',
            ),
          ),
        );
      }
      return;
    }
    final cubit = context.read<OfflineMapsCubit>();
    // Close sheet so the list screen is visible and can show download progress.
    Navigator.of(context).pop();
    cubit.downloadRegion(
      name: name,
      north: north,
      south: south,
      east: east,
      west: west,
      minZoom: minZ,
      maxZoom: maxZ,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfflineMapsCubit, OfflineMapsState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.downloadProgress != curr.downloadProgress ||
          prev.downloadTotal != curr.downloadTotal,
      builder: (context, state) {
        final isDownloading = state.status == OfflineMapsStatus.downloading;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Download map region',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Region name',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !isDownloading,
                ),
                const SizedBox(height: 8),
                _buildBboxSection(isDownloading),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minZoomController,
                        decoration: const InputDecoration(
                          labelText: 'Min zoom',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !isDownloading,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _maxZoomController,
                        decoration: const InputDecoration(
                          labelText: 'Max zoom',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !isDownloading,
                      ),
                    ),
                  ],
                ),
                if (isDownloading && state.downloadTotal > 0) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: state.downloadTotal > 0
                        ? state.downloadProgress / state.downloadTotal
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.downloadProgress} / ${state.downloadTotal} tiles (z${state.downloadZoom})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: isDownloading ? null : () => _startDownload(context),
                  child: Text(isDownloading ? 'Downloading…' : 'Download'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
