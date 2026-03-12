import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/bridge/lib.dart' as api;
import 'package:nav_e/core/domain/repositories/trip_repository.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';
import 'package:nav_e/features/offline_maps/cubit/offline_maps_cubit.dart';
import 'package:nav_e/features/offline_maps/cubit/offline_maps_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _totalKm = 0;
  int _totalDurationSeconds = 0;
  int _tripCount = 0;
  double _avgKm = 0;
  bool _loading = true;
  String? _error;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadStats();
      context.read<DevicesBloc>().add(LoadDevices());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<OfflineMapsCubit>().loadRegions();
      });
    }
  }

  Future<void> _loadStats() async {
    final repo = context.read<ITripRepository>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Trip count: from completed trips
      final trips = await repo.getAll();
      int count = 0;
      for (final t in trips) {
        if (t.status == 'Completed') count++;
      }

      // Distance, duration, avg: from actual tracked session data
      final statsJson = await api.getSessionStats();
      final stats = jsonDecode(statsJson) as Map<String, dynamic>;
      final totalDistM = (stats['total_distance_m'] as num).toDouble();
      final totalSec = (stats['total_duration_seconds'] as num).toInt();
      final sessionCount = (stats['session_count'] as num).toInt();

      if (mounted) {
        setState(() {
          _totalKm = totalDistM / 1000;
          _totalDurationSeconds = totalSec;
          _tripCount = count;
          _avgKm = sessionCount > 0 ? totalDistM / sessionCount / 1000 : 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}min';
    return '${minutes}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          _StatsCard(
            loading: _loading,
            error: _error,
            totalKm: _totalKm,
            totalDuration: _formatDuration(_totalDurationSeconds),
            tripCount: _tripCount,
            avgKm: _avgKm,
          ),
          const SizedBox(height: 16),
          _DevicesCard(onManage: () => context.pushNamed('devices')),
          const SizedBox(height: 16),
          _OfflineMapsCard(onManage: () => context.pushNamed('offlineMaps')),
          const SizedBox(height: 24),
          Text('More', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          _MoreCard(
            items: [
              _MoreItem(
                icon: Icons.history,
                label: 'Trip history',
                onTap: () => context.pushNamed('trips'),
              ),
              _MoreItem(
                icon: Icons.settings_outlined,
                label: 'App settings',
                onTap: () => context.pushNamed('settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats card ───────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.loading,
    required this.error,
    required this.totalKm,
    required this.totalDuration,
    required this.tripCount,
    required this.avgKm,
  });

  final bool loading;
  final String? error;
  final double totalKm;
  final String totalDuration;
  final int tripCount;
  final double avgKm;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your stats', style: textTheme.headlineSmall),
            const SizedBox(height: 16),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (error != null)
              Text(
                'Could not load stats',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _StatCell(
                    value: totalKm.toStringAsFixed(1),
                    unit: 'km',
                    label: 'total distance',
                    bg: colorScheme.primaryContainer,
                    fg: colorScheme.onPrimaryContainer,
                  ),
                  _StatCell(
                    value: totalDuration,
                    label: 'total time',
                    bg: colorScheme.secondaryContainer,
                    fg: colorScheme.onSecondaryContainer,
                  ),
                  _StatCell(
                    value: '$tripCount',
                    label: tripCount == 1 ? 'trip' : 'trips',
                    bg: colorScheme.tertiaryContainer,
                    fg: colorScheme.onTertiaryContainer,
                  ),
                  _StatCell(
                    value: avgKm.toStringAsFixed(1),
                    unit: 'km',
                    label: 'avg per trip',
                    bg: colorScheme.surfaceContainerHighest,
                    fg: colorScheme.onSurface,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    this.unit,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String value;
  final String? unit;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: textTheme.headlineSmall?.copyWith(color: fg),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(
                  unit!,
                  style: textTheme.bodySmall?.copyWith(
                    color: fg.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: fg.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Devices card ─────────────────────────────────────────────────────────────

class _DevicesCard extends StatelessWidget {
  const _DevicesCard({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.devices_outlined,
                color: colorScheme.onSecondaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: BlocBuilder<DevicesBloc, DevicesState>(
                builder: (context, state) {
                  final String subtitle;
                  if (state is DeviceLoadInProgress || state is DeviceInitial) {
                    subtitle = '…';
                  } else if (state is DeviceLoadSuccess) {
                    final n = state.devices.length;
                    subtitle = n == 0
                        ? 'No devices paired'
                        : '$n device${n == 1 ? '' : 's'} paired';
                  } else {
                    subtitle = 'No devices paired';
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Devices', style: textTheme.titleSmall),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            TextButton(onPressed: onManage, child: const Text('Manage')),
          ],
        ),
      ),
    );
  }
}

// ── Offline maps card ────────────────────────────────────────────────────────

class _OfflineMapsCard extends StatelessWidget {
  const _OfflineMapsCard({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.download_for_offline_outlined,
                color: colorScheme.onTertiaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: BlocBuilder<OfflineMapsCubit, OfflineMapsState>(
                builder: (context, state) {
                  final String subtitle;
                  if (state.status == OfflineMapsStatus.initial ||
                      state.status == OfflineMapsStatus.loading) {
                    subtitle = '…';
                  } else if (state.status == OfflineMapsStatus.loaded ||
                      state.status == OfflineMapsStatus.downloading) {
                    final n = state.regions.length;
                    subtitle = n == 0
                        ? 'No regions downloaded'
                        : '$n region${n == 1 ? '' : 's'} downloaded';
                  } else {
                    subtitle = 'No regions downloaded';
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Offline maps', style: textTheme.titleSmall),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            TextButton(onPressed: onManage, child: const Text('Manage')),
          ],
        ),
      ),
    );
  }
}

// ── More card ────────────────────────────────────────────────────────────────

class _MoreItem {
  const _MoreItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _MoreCard extends StatelessWidget {
  const _MoreCard({required this.items});

  final List<_MoreItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: colorScheme.outlineVariant,
              ),
            ListTile(
              leading: Icon(items[i].icon),
              title: Text(items[i].label),
              trailing: const Icon(Icons.chevron_right),
              onTap: items[i].onTap,
            ),
          ],
        ],
      ),
    );
  }
}
