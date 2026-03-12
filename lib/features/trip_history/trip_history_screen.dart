import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:nav_e/core/domain/entities/trip.dart';
import 'package:nav_e/core/widgets/state_views.dart';
import 'package:nav_e/features/trip_history/cubit/trip_history_cubit.dart';
import 'package:nav_e/features/trip_history/cubit/trip_history_state.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TripHistoryCubit>().loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Trip history'),
      ),
      body: BlocBuilder<TripHistoryCubit, TripHistoryState>(
        builder: (context, state) {
          if (state is TripHistoryLoading) {
            return const AppLoadingState(message: 'Loading trips...');
          }
          if (state is TripHistoryError) {
            return AppErrorState(
              message: state.message,
              onRetry: () => context.read<TripHistoryCubit>().loadTrips(),
            );
          }
          if (state is TripHistoryLoaded) {
            final trips = state.trips;
            if (trips.isEmpty) {
              return AppEmptyState(
                icon: Icons.route,
                title: 'No trips yet.',
                subtitle: 'Complete a route and tap "Finish" to save it here.',
                actionLabel: null,
                onAction: null,
              );
            }
            final colorScheme = Theme.of(context).colorScheme;
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: trips.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Dismissible(
                  key: ValueKey(
                    trip.id ?? '${trip.startedAt.millisecondsSinceEpoch}',
                  ),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  child: _TripListTile(
                    trip: trip,
                    onTap: () => context.pushNamed('tripDetail', extra: trip),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TripListTile extends StatelessWidget {
  const _TripListTile({required this.trip, required this.onTap});

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
        padding: const EdgeInsets.all(20),
        color: colorScheme.secondaryContainer,
        child: Row(
          children: [
            Icon(
              Icons.route,
              size: 20,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 4),
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
            const SizedBox(width: 12),
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
    final yesterday = today.subtract(const Duration(days: 1));
    if (tripDay == yesterday) {
      return 'Yesterday';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes > 0
        ? '${hours}h ${remainingMinutes}m'
        : '${hours}h';
  }
}
