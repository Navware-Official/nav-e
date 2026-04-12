import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/bridge/lib.dart' as api;
import 'package:nav_e/core/domain/entities/saved_place.dart';
import 'package:nav_e/core/domain/entities/trip.dart';
import 'package:nav_e/core/theme/spacing.dart';
import 'package:nav_e/features/location_preview/cubit/preview_cubit.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_state.dart';
import 'package:nav_e/features/trip_history/cubit/trip_history_cubit.dart';
import 'package:nav_e/features/trip_history/cubit/trip_history_state.dart';

/// Idle "home panel" shown at the bottom of the Map tab when no location
/// preview is active. Anchored to the bottom of the screen with a dark
/// background that visually merges with the bottom navigation bar.
class HomeIdlePanel extends StatefulWidget {
  const HomeIdlePanel({super.key});

  @override
  State<HomeIdlePanel> createState() => _HomeIdlePanelState();
}

class _HomeIdlePanelState extends State<HomeIdlePanel> {
  Map<String, dynamic>? _activeSession;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _loadActiveSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TripHistoryCubit>().loadTrips();
    });
  }

  Future<void> _loadActiveSession() async {
    try {
      final sessionJson = await api.getActiveSession();
      if (!mounted) return;
      if (sessionJson != null && sessionJson.isNotEmpty) {
        setState(
          () => _activeSession =
              jsonDecode(sessionJson) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // No active session — silently ignored.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.38,
      minChildSize: 0.15,
      maxChildSize: 0.75,
      snap: true,
      snapSizes: const [0.15, 0.38, 0.75],
      builder: (sheetCtx, scrollController) {
        return Material(
            color: colorScheme.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: colorScheme.outlineVariant),
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [
                const _DragHandle(),
                _HeroBlock(
                  onSearch: () => context.pushNamed('search'),
                  onRoutes: () => context.go('/routes'),
                ),
                if (_activeSession != null)
                  _ContinueRideBlock(
                    session: _activeSession!,
                    onTap: () => context
                        .pushNamed('activeNav', extra: _activeSession)
                        .then((_) {
                          if (mounted) _loadActiveSession();
                        }),
                  ),
                _SavedPlacesRow(),
                _RecentTripsRow(),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
        );
      },
    );
  }
}

// ── Drag handle ───────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 28, // off-grid
      child: Center(
        child: Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ── Hero block ────────────────────────────────────────────────────────────────

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({required this.onSearch, required this.onRoutes});

  final VoidCallback onSearch;
  final VoidCallback onRoutes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Card(
        color: colorScheme.primary,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start a ride',
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 6), // off-grid
              Text(
                'Search a destination and navigate',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: onSearch,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: onRoutes,
                    icon: const Icon(Icons.route_outlined),
                    label: const Text('Routes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Continue ride block ───────────────────────────────────────────────────────

class _ContinueRideBlock extends StatelessWidget {
  const _ContinueRideBlock({required this.session, required this.onTap});

  final Map<String, dynamic> session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final route = session['route'] as Map<String, dynamic>?;
    final distanceM = (route?['distance_meters'] as num?)?.toDouble();
    final waypoints = route?['waypoints'] as List<dynamic>?;
    final destinationLabel = waypoints != null && waypoints.isNotEmpty
        ? (waypoints.last as Map<String, dynamic>)['name'] as String?
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Card(
        color: colorScheme.primaryContainer,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.route,
                  size: 28, // off-grid
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Continue your ride',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        destinationLabel?.isNotEmpty == true
                            ? destinationLabel!
                            : (distanceM != null
                                ? '${(distanceM / 1000).toStringAsFixed(1)} km remaining'
                                : 'Resume navigation'),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Saved places row ──────────────────────────────────────────────────────────

class _SavedPlacesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavedPlacesCubit, SavedPlacesState>(
      builder: (context, state) {
        if (state is! SavedPlacesLoaded || state.places.isEmpty) {
          return const SizedBox.shrink();
        }
        final textTheme = Theme.of(context).textTheme;
        final colorScheme = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved places',
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.pushNamed('savedPlaces'),
                    child: const Text('See all'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                itemCount: state.places.length,
                itemBuilder: (context, index) {
                  final place = state.places[index];
                  return _PlaceChip(
                    place: place,
                    onTap: () => _navigateToPlace(context, place),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToPlace(BuildContext context, SavedPlace place) {
    context.read<PreviewCubit>().showCoords(
      lat: place.lat,
      lon: place.lon,
      label: place.name,
      placeId: place.id?.toString(),
    );
  }
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip({required this.place, required this.onTap});

  final SavedPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 130,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(color: colorScheme.tertiaryContainer),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.bookmark,
                size: 18,
                color: colorScheme.onTertiaryContainer,
              ),
              const SizedBox(height: 6), // off-grid
              Text(
                place.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recent trips row ──────────────────────────────────────────────────────────

class _RecentTripsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripHistoryCubit, TripHistoryState>(
      builder: (context, state) {
        if (state is! TripHistoryLoaded || state.trips.isEmpty) {
          return const SizedBox.shrink();
        }
        final textTheme = Theme.of(context).textTheme;
        final colorScheme = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent trips',
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/log'),
                    child: const Text('See all'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                itemCount: state.trips.length,
                itemBuilder: (context, index) {
                  final trip = state.trips[index];
                  return _TripChip(
                    trip: trip,
                    date: _formatDate(trip.completedAt),
                    duration: _formatDuration(trip.durationSeconds),
                    onTap: () =>
                        context.pushNamed('tripDetail', extra: trip),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripDay = DateTime(dt.year, dt.month, dt.day);
    if (tripDay == today) return 'Today';
    if (tripDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}

class _TripChip extends StatelessWidget {
  const _TripChip({
    required this.trip,
    required this.date,
    required this.duration,
    required this.onTap,
  });

  final Trip trip;
  final String date;
  final String duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(color: colorScheme.secondaryContainer),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.route,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 6), // off-grid
                  Expanded(
                    child: Text(
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
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${(trip.distanceM / 1000).toStringAsFixed(1)} km',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
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
      ),
    );
  }
}
