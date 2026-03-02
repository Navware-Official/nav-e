import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:nav_e/core/domain/entities/trip.dart';
import 'package:nav_e/core/domain/repositories/trip_repository.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/features/settings/widgets/trip_history_settings_section.dart';
import 'package:nav_e/features/map_layers/presentation/map_widget.dart';
import 'package:nav_e/features/map_layers/models/polyline_model.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/core/domain/repositories/map_source_repository.dart';

/// Payload for route finish screen (from active nav or route extra).
class RouteFinishPayload {
  final double distanceM;
  final double durationS;
  final DateTime startedAt;
  final DateTime completedAt;
  final bool completed;
  final String? destinationLabel;
  final String? routeId;
  final List<LatLng> routePoints;

  const RouteFinishPayload({
    required this.distanceM,
    required this.durationS,
    required this.startedAt,
    required this.completedAt,
    required this.completed,
    this.destinationLabel,
    this.routeId,
    required this.routePoints,
  });
}

class RouteFinishScreen extends StatefulWidget {
  final RouteFinishPayload payload;

  const RouteFinishScreen({super.key, required this.payload});

  @override
  State<RouteFinishScreen> createState() => _RouteFinishScreenState();
}

class _RouteFinishScreenState extends State<RouteFinishScreen> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoSave());
  }

  Future<void> _maybeAutoSave() async {
    final p = widget.payload;
    if (!p.completed || _saved) return;
    final autoSave = await getTripHistoryAutoSave();
    if (!autoSave || !mounted) return;
    await _saveTrip(context, p);
  }

  static String _encodePolyline(List<LatLng> points) {
    final list = points.map((p) => [p.latitude, p.longitude]).toList();
    return jsonEncode(list);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payload;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final actualDuration = p.completedAt.difference(p.startedAt);

    return BlocProvider(
      create: (context) =>
          MapBloc(context.read<IMapSourceRepository>())..add(MapInitialized()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(p.completed ? 'Route completed' : 'Route cancelled'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Map preview
              if (p.routePoints.length >= 2) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 160,
                    child: MapWidget(
                      markers: const [],
                      onMapTap: null,
                      onMapLongPress: null,
                      onDataLayerFeatureTap: null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _MapPreviewPolylineInitiator(routePoints: p.routePoints),
                const SizedBox(height: 16),
              ],

              // Headline
              Text(
                p.completed ? 'Route completed' : 'Route cancelled',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: p.completed
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Stats
              _StatRow(
                icon: Icons.straighten,
                label: 'Distance',
                value: '${(p.distanceM / 1000).toStringAsFixed(2)} km',
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
              _StatRow(
                icon: Icons.schedule,
                label: 'Estimated duration',
                value: '${(p.durationS / 60).round()} min',
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
              _StatRow(
                icon: Icons.timer,
                label: 'Actual duration',
                value: _formatDuration(actualDuration),
                colorScheme: colorScheme,
              ),
              if (p.destinationLabel != null &&
                  p.destinationLabel!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _StatRow(
                  icon: Icons.place,
                  label: 'Destination',
                  value: p.destinationLabel!,
                  colorScheme: colorScheme,
                ),
              ],
              const SizedBox(height: 24),

              // Primary actions
              if (p.completed) ...[
                FilledButton.icon(
                  onPressed: _saved ? null : () => _saveTrip(context, p),
                  icon: _saved
                      ? const Icon(Icons.check, size: 20)
                      : const Icon(Icons.save, size: 20),
                  label: Text(_saved ? 'Saved' : 'Save trip'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.done, size: 20),
                label: const Text('Done'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),

              // Later actions placeholder (e.g. Find parking, Show parking zones)
              const SizedBox(height: 24),
              const _LaterActionsPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTrip(BuildContext context, RouteFinishPayload p) async {
    final repo = context.read<ITripRepository>();
    final polylineEncoded = _encodePolyline(p.routePoints);
    final trip = Trip(
      distanceM: p.distanceM,
      durationSeconds: p.durationS.round(),
      startedAt: p.startedAt,
      completedAt: p.completedAt,
      status: 'completed',
      destinationLabel: p.destinationLabel,
      routeId: p.routeId,
      polylineEncoded: polylineEncoded,
    );
    await repo.insert(trip);
    if (mounted) setState(() => _saved = true);
  }

  static String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h}h ${m}min';
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Dispatches polyline to the local MapBloc so the map preview shows the route.
class _MapPreviewPolylineInitiator extends StatefulWidget {
  const _MapPreviewPolylineInitiator({required this.routePoints});

  final List<LatLng> routePoints;

  @override
  State<_MapPreviewPolylineInitiator> createState() =>
      _MapPreviewPolylineInitiatorState();
}

class _MapPreviewPolylineInitiatorState
    extends State<_MapPreviewPolylineInitiator> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_done && mounted && widget.routePoints.length >= 2) {
        context.read<MapBloc>().add(
          ReplacePolylines([
            PolylineModel(
              id: 'finish-preview',
              points: widget.routePoints,
              colorArgb: AppColors.blueRibbonDark02.toARGB32(),
              strokeWidth: 4.0,
            ),
          ], fit: true),
        );
        setState(() => _done = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Placeholder for future actions (Find parking, Show parking zones).
class _LaterActionsPlaceholder extends StatelessWidget {
  const _LaterActionsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.add_road, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'More actions (e.g. Find parking, Parking zones) — coming later',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
