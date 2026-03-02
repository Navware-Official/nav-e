import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/domain/repositories/map_source_repository.dart';
import 'package:nav_e/core/domain/repositories/saved_routes_repository.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/platform/route_import_channel.dart';
import 'package:nav_e/features/map_layers/models/marker_model.dart';
import 'package:nav_e/features/map_layers/models/polyline_model.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/map_widget.dart';
import 'package:nav_e/features/map_layers/presentation/utils/polyline_utils.dart';

/// Screen to import a route: empty state with file picker, then preview and Save/Cancel.
class ImportPreviewScreen extends StatefulWidget {
  const ImportPreviewScreen({super.key, this.routeJson, this.source = 'gpx'});

  /// When null, shows empty state so user can pick a file. When set, shows route preview.
  final String? routeJson;
  final String source;

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  bool _saving = false;
  bool _loading = false;
  bool _mapExpanded = false;

  /// Current route JSON to show (from initial widget or after picking file).
  String? _routeJson;
  Map<String, dynamic>? _parsed;

  @override
  void initState() {
    super.initState();
    _routeJson = widget.routeJson;
    _parseRouteJson();
  }

  void _parseRouteJson() {
    final json = _routeJson;
    if (json == null || json.isEmpty) {
      setState(() => _parsed = null);
      return;
    }
    try {
      setState(() => _parsed = jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      setState(() => _parsed = null);
    }
  }

  Future<void> _pickFile() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (!mounted) return;
      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final file = result.files.single;
      final name = file.name.toLowerCase();
      if (!name.endsWith('.gpx')) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Please select a .gpx file')),
        );
        setState(() => _loading = false);
        return;
      }
      List<int> bytes = file.bytes?.toList() ?? [];
      if (bytes.isEmpty && file.path != null && file.path!.isNotEmpty) {
        final path = file.path!;
        final uriPath =
            path.startsWith('content://') || path.startsWith('file://')
            ? path
            : 'file://$path';
        bytes = await readFileFromUri(uriPath);
      }
      if (bytes.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not read file')),
        );
        setState(() => _loading = false);
        return;
      }
      final repo = context.read<ISavedRoutesRepository>();
      final routeJson = await repo.parseRouteFromGpxBytes(bytes);
      if (!mounted) return;
      setState(() {
        _routeJson = routeJson;
        _loading = false;
      });
      _parseRouteJson();
    } catch (e, st) {
      debugPrint('Import GPX error: $e\n$st');
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _onSave() async {
    final json = _routeJson;
    if (_saving || _parsed == null || json == null) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = context.read<ISavedRoutesRepository>();
      await repo.saveRouteFromJson(json, widget.source);
      if (!mounted) return;
      context.goNamed('savedRoutes');
      messenger.showSnackBar(const SnackBar(content: Text('Route saved')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_parsed == null) {
      final isInvalid = _routeJson != null && _routeJson!.isNotEmpty;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Import route'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
          ),
        ),
        body: isInvalid
            ? const Center(child: Text('Invalid route data'))
            : _buildEmptyState(context),
      );
    }

    final metadata = _parsed!['metadata'] as Map<String, dynamic>? ?? {};
    final sourceObj = metadata['source'] as Map<String, dynamic>?;
    final name = metadata['name'] as String? ?? 'Unnamed route';
    final description = metadata['description'] as String?;
    final distanceM = metadata['total_distance_m'] as num?;
    final durationS = metadata['estimated_duration_s'] as num?;
    final tags = metadata['tags'] as List<dynamic>? ?? [];
    final segments = _parsed!['segments'] as List<dynamic>? ?? [];
    final segmentCount = segments.length;
    final creator = sourceObj?['creator'] as String?;
    final format = sourceObj?['format'] as String? ?? widget.source;
    final extras = sourceObj?['extras'] as Map<String, dynamic>?;
    final typeStr = extras?['type'] as String? ?? format;
    final routeComment = extras?['comment'] as String?;

    List<Map<String, dynamic>> waypointsList = [];
    if (segments.isNotEmpty) {
      final seg = segments.first as Map<String, dynamic>;
      waypointsList = (seg['waypoints'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
    }

    final distanceStr = distanceM != null
        ? '${(distanceM.toDouble() / 1000).toStringAsFixed(2)} km'
        : '—';
    final durationStr = durationS != null
        ? '${Duration(seconds: durationS.toInt()).inMinutes} min'
        : '—';

    String? polylineEncoded;
    if (segments.isNotEmpty) {
      final geom =
          (segments.first as Map<String, dynamic>)['geometry']
              as Map<String, dynamic>?;
      if (geom != null) {
        final p = geom['polyline'];
        if (p is String) {
          polylineEncoded = p;
        } else if (p is List && p.isNotEmpty && p.first is String) {
          polylineEncoded = p.first as String;
        }
      }
    }
    final mapPoints = polylineEncoded != null && polylineEncoded.isNotEmpty
        ? PolylineUtils.decodePolyline(polylineEncoded)
        : <LatLng>[];

    // Markers for each stop/waypoint on the map
    final stopMarkers = <MarkerModel>[];
    for (var i = 0; i < waypointsList.length; i++) {
      final w = waypointsList[i];
      final coord = w['coordinate'] as Map<String, dynamic>?;
      final lat = coord?['latitude'] as num?;
      final lon = coord?['longitude'] as num?;
      if (lat != null && lon != null) {
        final kind = w['kind'] as String? ?? 'Via';
        final colorScheme = Theme.of(context).colorScheme;
        final icon = kind == 'Start'
            ? Icon(Icons.flag, color: colorScheme.primary, size: 36)
            : kind == 'Stop'
            ? Icon(Icons.place, color: colorScheme.error, size: 36)
            : Icon(Icons.trip_origin, color: colorScheme.primary, size: 28);
        stopMarkers.add(
          MarkerModel(
            id: 'stop_$i',
            position: LatLng(lat.toDouble(), lon.toDouble()),
            icon: icon,
            width: 40,
            height: 40,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import route'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._buildContentAboveMap(
              name: name,
              description: description,
              routeComment: routeComment,
              creator: creator,
              typeStr: typeStr,
              distanceStr: distanceStr,
              durationStr: durationStr,
              segmentCount: segmentCount,
              tags: tags,
              showMapLabel: mapPoints.length >= 2,
            ),
            if (mapPoints.length >= 2) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    SizedBox(
                      height: _mapExpanded
                          ? MediaQuery.sizeOf(context).height * 0.6
                          : 200,
                      child: BlocProvider(
                        create: (context) =>
                            MapBloc(context.read<IMapSourceRepository>())
                              ..add(MapInitialized()),
                        child: Stack(
                          children: [
                            MapWidget(
                              markers: stopMarkers,
                              onMapTap: null,
                              onMapLongPress: null,
                              onDataLayerFeatureTap: null,
                              fitPadding: const EdgeInsets.all(24),
                            ),
                            _ImportPreviewMapPolylineInitiator(
                              points: mapPoints,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        child: IconButton(
                          icon: Icon(
                            _mapExpanded
                                ? Icons.close_fullscreen
                                : Icons.open_in_full,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () {
                            setState(() => _mapExpanded = !_mapExpanded);
                          },
                          tooltip: _mapExpanded ? 'Collapse map' : 'Expand map',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ..._buildContentBelowMap(
              waypointsList: waypointsList,
              onSave: _onSave,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContentAboveMap({
    required String name,
    required String? description,
    required String? routeComment,
    required String? creator,
    required String typeStr,
    required String distanceStr,
    required String durationStr,
    required int segmentCount,
    required List<dynamic> tags,
    required bool showMapLabel,
  }) {
    return [
      Text(
        name,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      if (description != null && description.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
      ],
      if (routeComment != null &&
          routeComment.isNotEmpty &&
          routeComment != description) ...[
        const SizedBox(height: 8),
        Text(
          routeComment,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
      const SizedBox(height: 16),
      if (creator != null && creator.isNotEmpty)
        _DetailRow(label: 'Creator', value: creator),
      _DetailRow(label: 'Type', value: typeStr),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _MetricChip(icon: Icons.straighten, label: distanceStr),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricChip(icon: Icons.schedule, label: durationStr),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _DetailRow(label: 'Segments', value: '$segmentCount'),
      if (tags.isNotEmpty)
        _DetailRow(
          label: 'Tags',
          value: tags.map((e) => e.toString()).join(', '),
        ),
      if (showMapLabel) ...[
        const SizedBox(height: 20),
        Text(
          'Map preview',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  List<Widget> _buildContentBelowMap({
    required List<Map<String, dynamic>> waypointsList,
    required VoidCallback onSave,
  }) {
    return [
      if (waypointsList.isNotEmpty) ...[
        const SizedBox(height: 16),
        Material(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          child: ExpansionTile(
            initiallyExpanded: false,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Text(
              'Waypoints',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${waypointsList.length} stops',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            children: [
              ...waypointsList.asMap().entries.map((e) {
                final i = e.key + 1;
                final w = e.value;
                final coord = w['coordinate'] as Map<String, dynamic>?;
                final lat = coord?['latitude'] as num?;
                final lon = coord?['longitude'] as num?;
                final kind = w['kind'] as String? ?? '—';
                final wpName = w['name'] as String?;
                final wpDesc = w['description'] as String?;
                final label = wpName?.isNotEmpty == true
                    ? wpName!
                    : (kind == 'Start'
                          ? 'Start'
                          : kind == 'Stop'
                          ? 'Stop'
                          : 'Via $i');
                final coordsStr = (lat != null && lon != null)
                    ? '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}'
                    : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$i.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            if (wpDesc != null && wpDesc.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  wpDesc,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            if (coordsStr.isNotEmpty)
                              Text(
                                coordsStr,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          kind,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        if (waypointsList.any(
          (w) => (w['description'] as String? ?? '').isNotEmpty,
        )) ...[
          const SizedBox(height: 16),
          Text(
            'Stops with descriptions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          ...waypointsList
              .asMap()
              .entries
              .where(
                (e) => (e.value['description'] as String? ?? '').isNotEmpty,
              )
              .map((e) {
                final i = e.key + 1;
                final w = e.value;
                final wpName = w['name'] as String?;
                final wpDesc = w['description'] as String? ?? '';
                final kind = w['kind'] as String? ?? '—';
                final label = wpName?.isNotEmpty == true
                    ? wpName!
                    : 'Stop $i ($kind)';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          wpDesc,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
        ],
      ],
      const SizedBox(height: 32),
      FilledButton.icon(
        onPressed: _saving ? null : onSave,
        icon: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_saving ? 'Saving…' : 'Save route'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
    ];
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Import a GPX route',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a .gpx file to preview and save the route.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loading ? null : _pickFile,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.folder_open),
              label: Text(_loading ? 'Loading…' : 'Select GPX file'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pushes the route polyline to MapBloc after the map is ready.
class _ImportPreviewMapPolylineInitiator extends StatefulWidget {
  const _ImportPreviewMapPolylineInitiator({required this.points});

  final List<LatLng> points;

  @override
  State<_ImportPreviewMapPolylineInitiator> createState() =>
      _ImportPreviewMapPolylineInitiatorState();
}

class _ImportPreviewMapPolylineInitiatorState
    extends State<_ImportPreviewMapPolylineInitiator> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_done || !mounted || widget.points.length < 2) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      context.read<MapBloc>().add(
        ReplacePolylines([
          PolylineModel(
            id: 'import-preview-route',
            points: widget.points,
            colorArgb: AppColors.blueRibbonDark02.value,
            strokeWidth: 4.0,
          ),
        ], fit: true),
      );
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
