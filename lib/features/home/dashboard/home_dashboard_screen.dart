import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/bridge/lib.dart' as api;
import 'package:nav_e/core/domain/entities/saved_place.dart';
import 'package:nav_e/core/domain/entities/trip.dart';
import 'package:nav_e/features/location_preview/cubit/preview_cubit.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_state.dart';
import 'package:nav_e/features/trip_history/cubit/trip_history_cubit.dart';
import 'package:nav_e/features/trip_history/cubit/trip_history_state.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  bool _loaded = false;
  Map<String, dynamic>? _activeSession;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      context.read<TripHistoryCubit>().loadTrips();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<SavedPlacesCubit>().loadPlaces();
      });
      _loadActiveSession();
    }
  }

  Future<void> _loadActiveSession() async {
    try {
      final sessionJson = await api.getActiveSession();
      if (!mounted) return;
      if (sessionJson != null && sessionJson.isNotEmpty) {
        final session = jsonDecode(sessionJson) as Map<String, dynamic>;
        setState(() => _activeSession = session);
      } else {
        setState(() => _activeSession = null);
      }
    } catch (_) {
      if (mounted) setState(() => _activeSession = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listChildren = <Widget>[_HeroCard(onTap: () => context.go('/'))];
    if (_activeSession != null) {
      listChildren.add(
        _RecentIncompleteSessionCard(
          session: _activeSession!,
          onTap: () {
            context.pushNamed('activeNav', extra: _activeSession).then((_) {
              if (mounted) _loadActiveSession();
            });
          },
        ),
      );
    }
    listChildren.addAll([
      _PlacesCarousel(),
      const SizedBox(height: 28),
      _RecentTripsCarousel(),
      const SizedBox(height: 16),
    ]);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: listChildren,
      ),
    );
  }
}

// ── Recent incomplete session (under Start a ride) ────────────────────────────

class _RecentIncompleteSessionCard extends StatelessWidget {
  const _RecentIncompleteSessionCard({
    required this.session,
    required this.onTap,
  });

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

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: const RoundedRectangleBorder(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.route,
                size: 32,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Text(
                      destinationLabel?.isNotEmpty == true
                          ? destinationLabel!
                          : (distanceM != null
                                ? '${(distanceM / 1000).toStringAsFixed(1)} km remaining'
                                : 'Resume navigation'),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.primary,
      shape: const RoundedRectangleBorder(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start a ride',
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Search a destination and navigate',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.tonal(
                      onPressed: onTap,
                      child: const Text('Open map'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Saved places carousel ────────────────────────────────────────────────────

class _PlacesCarousel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<SavedPlacesCubit, SavedPlacesState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saved places', style: textTheme.headlineSmall),
                TextButton(
                  onPressed: () => context.pushNamed('savedPlaces'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state is SavedPlacesLoading)
              const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is SavedPlacesLoaded && state.places.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No saved places yet.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else if (state is SavedPlacesLoaded)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.places.length,
                  itemBuilder: (context, index) {
                    final place = state.places[index];
                    return _PlaceChipCard(
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

class _PlaceChipCard extends StatelessWidget {
  const _PlaceChipCard({required this.place, required this.onTap});

  final SavedPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 130,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: colorScheme.tertiaryContainer),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.bookmark,
                size: 18,
                color: colorScheme.onTertiaryContainer,
              ),
              const SizedBox(height: 6),
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

// ── Recent trips carousel ────────────────────────────────────────────────────

class _RecentTripsCarousel extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<TripHistoryCubit, TripHistoryState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent trips', style: textTheme.headlineSmall),
                TextButton(
                  onPressed: () => context.pushNamed('trips'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state is TripHistoryLoading)
              const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is TripHistoryLoaded && state.trips.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No trips yet. Complete a route to see it here.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else if (state is TripHistoryLoaded)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.trips.length,
                  itemBuilder: (context, index) {
                    final trip = state.trips[index];
                    return _TripCard(
                      trip: trip,
                      date: _formatDate(trip.completedAt),
                      duration: _formatDuration(trip.durationSeconds),
                      onTap: () => context.pushNamed('tripDetail', extra: trip),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
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
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(14),
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
                  const SizedBox(width: 6),
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
              const SizedBox(height: 2),
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
