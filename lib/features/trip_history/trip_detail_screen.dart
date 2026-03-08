import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:nav_e/core/domain/entities/trip.dart';
import 'package:nav_e/core/theme/palette.dart';
import 'package:nav_e/features/map_layers/presentation/map_widget.dart';
import 'package:nav_e/features/map_layers/models/polyline_model.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/core/domain/repositories/map_source_repository.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key, required this.trip});

  final Trip trip;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  bool _mapExpanded = false;

  static List<LatLng> _decodePolyline(String? encoded) {
    if (encoded == null || encoded.isEmpty) return [];
    try {
      final list = jsonDecode(encoded) as List<dynamic>;
      return list
          .map((e) {
            final pair = e as List<dynamic>;
            if (pair.length >= 2) {
              return LatLng(
                (pair[0] as num).toDouble(),
                (pair[1] as num).toDouble(),
              );
            }
            return null;
          })
          .whereType<LatLng>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final points = _decodePolyline(widget.trip.polylineEncoded);
    final actualDuration = widget.trip.completedAt.difference(
      widget.trip.startedAt,
    );
    final mapHeight = _mapExpanded
        ? MediaQuery.sizeOf(context).height * 0.6
        : 200.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.trip.destinationLabel?.isNotEmpty == true
              ? widget.trip.destinationLabel!
              : 'Trip',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (points.length >= 2) ...[
              BlocProvider(
                create: (context) =>
                    MapBloc(context.read<IMapSourceRepository>())
                      ..add(MapInitialized()),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          SizedBox(
                            height: mapHeight,
                            child: MapWidget(
                              markers: const [],
                              onMapTap: null,
                              onMapLongPress: null,
                              onDataLayerFeatureTap: null,
                              fitPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: colorScheme.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              child: IconButton(
                                icon: Icon(
                                  _mapExpanded
                                      ? Icons.close_fullscreen
                                      : Icons.open_in_full,
                                  color: colorScheme.onSurface,
                                ),
                                onPressed: () {
                                  setState(() => _mapExpanded = !_mapExpanded);
                                },
                                tooltip: _mapExpanded
                                    ? 'Collapse map'
                                    : 'Expand map',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TripDetailMapPolylineInitiator(points: points),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            _StatRow(
              icon: Icons.straighten,
              label: 'Distance',
              value: '${(widget.trip.distanceM / 1000).toStringAsFixed(2)} km',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.schedule,
              label: 'Duration',
              value: '${(widget.trip.durationSeconds / 60).round()} min',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.timer,
              label: 'Actual',
              value: _formatDuration(actualDuration),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.calendar_today,
              label: 'Completed',
              value: _formatDateTime(widget.trip.completedAt),
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h}h ${m}min';
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

class _TripDetailMapPolylineInitiator extends StatefulWidget {
  const _TripDetailMapPolylineInitiator({required this.points});

  final List<LatLng> points;

  @override
  State<_TripDetailMapPolylineInitiator> createState() =>
      _TripDetailMapPolylineInitiatorState();
}

class _TripDetailMapPolylineInitiatorState
    extends State<_TripDetailMapPolylineInitiator> {
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
            id: 'trip-detail-preview',
            points: widget.points,
            colorArgb: AppPalette.blueRibbonDark02.toARGB32(),
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
