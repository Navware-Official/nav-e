import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: trips.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final trip = trips[index];
                return ListTile(
                  leading: Icon(
                    Icons.route,
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
                    '${(trip.distanceM / 1000).toStringAsFixed(2)} km · '
                    '${_formatDate(trip.completedAt)}',
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
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
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
}
