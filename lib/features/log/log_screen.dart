import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/bridge/lib.dart' as api;
import 'package:nav_e/core/domain/entities/saved_place.dart';
import 'package:nav_e/core/domain/entities/trip.dart';
import 'package:nav_e/core/domain/repositories/trip_repository.dart';
import 'package:nav_e/core/theme/spacing.dart';
import 'package:nav_e/core/widgets/state_views.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_state.dart';
import 'package:nav_e/features/trip_history/cubit/trip_history_cubit.dart';
import 'package:nav_e/features/trip_history/cubit/trip_history_state.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key, this.initialSegment = 'trips'});

  /// Which segment to show on first load: 'trips' or 'places'.
  final String initialSegment;

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  late String _segment = widget.initialSegment;
  double _totalKm = 0;
  int _tripCount = 0;
  bool _statsLoading = true;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _loadStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TripHistoryCubit>().loadTrips();
      context.read<SavedPlacesCubit>().loadPlaces();
    });
  }

  Future<void> _loadStats() async {
    try {
      final repo = context.read<ITripRepository>();
      final trips = await repo.getAll();
      int count = 0;
      for (final t in trips) {
        if (t.status == 'completed') count++;
      }
      final stats = await api.getSessionStats();
      final totalDistM = stats.totalDistanceM;
      if (mounted) {
        setState(() {
          _totalKm = totalDistM / 1000;
          _tripCount = count;
          _statsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatsHeader(
            loading: _statsLoading,
            totalKm: _totalKm,
            tripCount: _tripCount,
          ),
          _SegmentControl(
            selected: _segment,
            onChanged: (v) => setState(() => _segment = v),
          ),
          Expanded(child: _segment == 'trips' ? _TripsView() : _PlacesView()),
        ],
      ),
    );
  }
}

// ── Stats header ──────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.loading,
    required this.totalKm,
    required this.tripCount,
  });

  final bool loading;
  final double totalKm;
  final int tripCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: loading
            ? const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator()),
              )
            : Row(
                children: [
                  _StatItem(
                    value: totalKm.toStringAsFixed(1),
                    unit: 'km',
                    label: 'ridden',
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: colorScheme.outlineVariant,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                  ),
                  _StatItem(
                    value: '$tripCount',
                    label: tripCount == 1 ? 'trip' : 'trips',
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, this.unit, required this.label});

  final String value;
  final String? unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        if (unit != null) ...[
          const SizedBox(width: 3), // off-grid
          Text(
            unit!,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── Segment control ───────────────────────────────────────────────────────────

class _SegmentControl extends StatelessWidget {
  const _SegmentControl({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'trips',
            label: Text('Trips'),
            icon: Icon(Icons.history_outlined),
          ),
          ButtonSegment(
            value: 'places',
            label: Text('Places'),
            icon: Icon(Icons.bookmark_border),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (v) => onChanged(v.first),
        showSelectedIcon: false,
      ),
    );
  }
}

// ── Trips view ────────────────────────────────────────────────────────────────

class _TripsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripHistoryCubit, TripHistoryState>(
      builder: (context, state) {
        if (state is TripHistoryLoading) {
          return const AppLoadingState(message: 'Loading trips…');
        }
        if (state is TripHistoryError) {
          return AppErrorState(
            message: state.message,
            onRetry: () => context.read<TripHistoryCubit>().loadTrips(),
          );
        }
        if (state is TripHistoryLoaded) {
          if (state.trips.isEmpty) {
            return const AppEmptyState(
              icon: Icons.route,
              title: 'No trips yet.',
              subtitle: 'Complete a route and tap "Finish" to save it here.',
            );
          }
          final colorScheme = Theme.of(context).colorScheme;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: state.trips.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final trip = state.trips[index];
              return Dismissible(
                key: ValueKey(
                  trip.id ?? '${trip.startedAt.millisecondsSinceEpoch}',
                ),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Icon(Icons.delete, color: colorScheme.onError),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete trip'),
                          content: const Text(
                            'Remove this trip from your history?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) {
                  if (trip.id != null) {
                    context.read<TripHistoryCubit>().deleteTrip(trip.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trip deleted')),
                    );
                  }
                },
                child: _TripTile(
                  trip: trip,
                  onTap: () => context.pushNamed('tripDetail', extra: trip),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final date = _formatDate(trip.completedAt);
    final duration = _formatDuration(trip.durationSeconds);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        color: colorScheme.secondaryContainer,
        child: Row(
          children: [
            Icon(
              Icons.route,
              size: 20,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.destinationLabel?.isNotEmpty == true
                        ? trip.destinationLabel!
                        : 'Trip',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$duration · $date',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${(trip.distanceM / 1000).toStringAsFixed(1)} km',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripDay = DateTime(dt.year, dt.month, dt.day);
    if (tripDay == today) {
      return 'Today ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (tripDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return rem > 0 ? '${hours}h ${rem}m' : '${hours}h';
  }
}

// ── Places view ───────────────────────────────────────────────────────────────

class _PlacesView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavedPlacesCubit, SavedPlacesState>(
      builder: (context, state) {
        if (state is SavedPlacesInitial || state is SavedPlacesLoading) {
          return const AppLoadingState(message: 'Loading places…');
        }
        if (state is SavedPlacesError) {
          return AppErrorState(
            message: state.message,
            onRetry: () => context.read<SavedPlacesCubit>().loadPlaces(),
          );
        }
        if (state is SavedPlacesLoaded) {
          if (state.places.isEmpty) {
            return const AppEmptyState(
              icon: Icons.bookmark_border,
              title: 'No saved places yet.',
              subtitle:
                  'Long-press the map or search for a location and tap "Save".',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: state.places.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final place = state.places[index];
              final colorScheme = Theme.of(context).colorScheme;
              final stableKey = place.id != null
                  ? 'place_${place.id}'
                  : 'place_${place.lat}_${place.lon}_${place.name}';
              return Dismissible(
                key: ValueKey(stableKey),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Icon(Icons.delete, color: colorScheme.onError),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete place'),
                          content: Text('Remove "${place.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) async {
                  if (place.id != null) {
                    final messenger = ScaffoldMessenger.of(context);
                    await context.read<SavedPlacesCubit>().deletePlace(
                      place.id!,
                    );
                    if (context.mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Deleted "${place.name}"')),
                      );
                    }
                  }
                },
                child: _PlaceTile(
                  place: place,
                  onTap: () => _showOnMap(context, place),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showOnMap(BuildContext context, SavedPlace place) {
    final uri = Uri(
      path: '/',
      queryParameters: <String, String>{
        'lat': place.lat.toStringAsFixed(6),
        'lon': place.lon.toStringAsFixed(6),
        'label': place.name,
        if (place.id != null) 'placeId': place.id.toString(),
        'zoom': '14',
      },
    );
    context.go(uri.toString());
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.onTap});

  final SavedPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        color: colorScheme.secondaryContainer,
        child: Row(
          children: [
            Icon(
              Icons.place,
              size: 20,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (place.address != null && place.address!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      place.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            Icon(Icons.chevron_right, color: colorScheme.onSecondaryContainer),
          ],
        ),
      ),
    );
  }
}
