import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/domain/entities/saved_place.dart';
import 'package:nav_e/core/domain/entities/saved_route.dart';
import 'package:nav_e/core/domain/entities/trip.dart';
import 'package:nav_e/core/domain/entities/offline_region.dart';
import 'package:nav_e/core/domain/repositories/offline_regions_repository.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';
import 'package:nav_e/features/location_preview/cubit/preview_cubit.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_state.dart';
import 'package:nav_e/features/saved_routes/cubit/saved_routes_cubit.dart';
import 'package:nav_e/features/saved_routes/cubit/saved_routes_state.dart';
import 'package:nav_e/features/saved_routes/route_enrichment.dart';
import 'package:nav_e/features/trip_history/cubit/trip_history_cubit.dart';
import 'package:nav_e/features/trip_history/cubit/trip_history_state.dart';

const int _previewCount = 5;

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  bool _tripsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tripsLoaded) {
      _tripsLoaded = true;
      context.read<TripHistoryCubit>().loadTrips();
      context.read<DevicesBloc>().add(LoadDevices());
      context.read<SavedRoutesCubit>().loadRoutes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Plan a route'),
              subtitle: const Text('Search and plan on the map'),
              onTap: () => context.go('/'),
            ),
          ),
          const SizedBox(height: 24),
          _SavedPlacesSection(),
          const SizedBox(height: 24),
          _HomeSavedRoutesSection(),
          const SizedBox(height: 24),
          _DevicesSection(),
          const SizedBox(height: 24),
          _OfflineMapsSection(),
          const SizedBox(height: 24),
          _RecentTripsSection(),
        ],
      ),
    );
  }
}

class _HomeSavedRoutesSection extends StatelessWidget {
  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _subtitleText(SavedRoute route, RouteEnrichment e) {
    final parts = <String>['${route.source} · ${_formatDate(route.createdAt)}'];
    if (e.distanceKm != null)
      parts.add('${e.distanceKm!.toStringAsFixed(1)} km');
    if (e.durationMinutes != null) parts.add('${e.durationMinutes} min');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavedRoutesCubit, SavedRoutesState>(
      builder: (context, state) {
        final routes = state is SavedRoutesLoaded
            ? state.routes.take(_previewCount).toList()
            : <SavedRoute>[];
        final enrichments = state is SavedRoutesLoaded
            ? state.enrichments.take(_previewCount).toList()
            : <RouteEnrichment>[];
        final hasMore =
            state is SavedRoutesLoaded && state.routes.length > _previewCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved routes',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextButton(
                  onPressed: () => context.pushNamed('savedRoutes'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state is SavedRoutesLoading && routes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (routes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No saved routes yet. Import a GPX or save a route from the map.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...List.generate(routes.length, (i) {
                final route = routes[i];
                final enrichment = i < enrichments.length
                    ? enrichments[i]
                    : const RouteEnrichment();
                return ListTile(
                  leading: const Icon(Icons.route, size: 20),
                  title: Text(
                    route.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _subtitleText(route, enrichment),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () =>
                      context.pushNamed('savedRoutePreview', extra: route),
                );
              }),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton(
                  onPressed: () => context.pushNamed('savedRoutes'),
                  child: const Text('See all'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DevicesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DevicesBloc, DevicesState>(
      builder: (context, state) {
        final count = state is DeviceLoadSuccess ? state.devices.length : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Devices', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.devices, size: 20),
              title: const Text('Device management'),
              subtitle: Text(
                count != null ? '$count device(s)' : 'Manage devices',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () => context.push('/devices'),
            ),
          ],
        );
      },
    );
  }
}

class _OfflineMapsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Offline maps', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        FutureBuilder<List<OfflineRegion>>(
          future: context.read<IOfflineRegionsRepository>().getAll(),
          builder: (context, snapshot) {
            final count = snapshot.hasData ? snapshot.data!.length : null;
            return ListTile(
              leading: const Icon(Icons.map_outlined, size: 20),
              title: const Text('Offline maps'),
              subtitle: Text(
                count != null
                    ? '$count region(s) downloaded'
                    : 'Manage offline maps',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () => context.push('/offline-maps'),
            );
          },
        ),
      ],
    );
  }
}

class _SavedPlacesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavedPlacesCubit, SavedPlacesState>(
      builder: (context, state) {
        final places = state is SavedPlacesLoaded
            ? state.places.take(_previewCount).toList()
            : <SavedPlace>[];
        final hasMore =
            state is SavedPlacesLoaded && state.places.length > _previewCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved places',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextButton(
                  onPressed: () => context.pushNamed('savedPlaces'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state is SavedPlacesLoading && places.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (places.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No saved places yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...places.map(
                (p) => ListTile(
                  leading: const Icon(Icons.bookmark_border, size: 20),
                  title: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: p.address != null && p.address!.isNotEmpty
                      ? Text(
                          p.address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () {
                    context.read<PreviewCubit>().showCoords(
                      lat: p.lat,
                      lon: p.lon,
                      label: p.name,
                      placeId: p.id?.toString(),
                    );
                    final uri = Uri(
                      path: '/',
                      queryParameters: <String, String>{
                        'lat': p.lat.toStringAsFixed(6),
                        'lon': p.lon.toStringAsFixed(6),
                        'label': p.name,
                        if (p.id != null) 'placeId': p.id.toString(),
                        'zoom': '14',
                      },
                    );
                    context.go(uri.toString());
                  },
                ),
              ),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton(
                  onPressed: () => context.pushNamed('savedPlaces'),
                  child: const Text('See all'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecentTripsSection extends StatelessWidget {
  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripDay = DateTime(dt.year, dt.month, dt.day);
    if (tripDay == today) {
      return 'Today ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (tripDay == yesterday) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripHistoryCubit, TripHistoryState>(
      builder: (context, state) {
        final trips = state is TripHistoryLoaded
            ? state.trips.take(_previewCount).toList()
            : <Trip>[];
        final hasMore =
            state is TripHistoryLoaded && state.trips.length > _previewCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent trips',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextButton(
                  onPressed: () => context.pushNamed('trips'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state is TripHistoryLoading && trips.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (trips.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No trips yet. Complete a route and tap "Finish" to save it here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...trips.map(
                (trip) => ListTile(
                  leading: Icon(
                    Icons.route,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    trip.destinationLabel?.isNotEmpty == true
                        ? trip.destinationLabel!
                        : 'Trip',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${(trip.distanceM / 1000).toStringAsFixed(2)} km · ${_formatDate(trip.completedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${(trip.durationSeconds / 60).round()} min',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => context.pushNamed('tripDetail', extra: trip),
                ),
              ),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton(
                  onPressed: () => context.pushNamed('trips'),
                  child: const Text('See all'),
                ),
              ),
          ],
        );
      },
    );
  }
}
