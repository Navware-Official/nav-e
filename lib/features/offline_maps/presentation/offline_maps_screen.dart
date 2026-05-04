import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:nav_e/bridge/lib.dart' as rust_api;
import 'package:nav_e/core/device_comm/device_comm_transport.dart';
import 'package:nav_e/features/device_comm/device_comm_bloc.dart';
import 'package:nav_e/features/device_comm/presentation/bloc/device_comm_events.dart';
import 'package:nav_e/features/device_comm/presentation/bloc/device_comm_states.dart';
import 'package:nav_e/features/offline_maps/cubit/offline_maps_cubit.dart';
import 'package:nav_e/features/offline_maps/cubit/offline_maps_state.dart';
import 'package:nav_e/features/offline_maps/data/available_region.dart';
import 'package:nav_e/core/domain/entities/offline_region.dart';

/// Single-page offline maps UI.
///
/// Lists the regions advertised by the nav-dsp gateway up top with inline
/// download buttons; lists already-downloaded regions below with delete and
/// "send to device" actions. No modal sheets — the catalog and the local list
/// are always both visible so the user can see at a glance what is downloaded,
/// what is available, and what's in flight.
///
/// Uses the app-level [OfflineMapsCubit] provided in `main.dart`; do not wrap
/// in another BlocProvider here.
class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<OfflineMapsCubit>();
    cubit.loadRegions();
    cubit.loadAvailableRegions();
  }

  String _readBaseUrl() {
    try {
      final url = rust_api.getNavdspBaseUrl();
      return url.isEmpty ? '(no URL configured)' : url;
    } catch (e) {
      return '(failed to read URL)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OfflineMapsCubit, OfflineMapsState>(
          listenWhen: (prev, curr) =>
              prev.status == OfflineMapsStatus.downloading &&
              (curr.status == OfflineMapsStatus.loaded ||
                  curr.status == OfflineMapsStatus.error),
          listener: (context, state) {
            if (state.status == OfflineMapsStatus.loaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Region downloaded')),
              );
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
        ),
        BlocListener<DeviceCommBloc, DeviceCommState>(
          listenWhen: (prev, curr) =>
              curr is DeviceCommSuccess || curr is DeviceCommError,
          listener: (context, state) {
            if (state is DeviceCommSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Map region sent to device')),
              );
            } else if (state is DeviceCommError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Offline maps'),
              Text(
                _readBaseUrl(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh catalog',
              onPressed: () =>
                  context.read<OfflineMapsCubit>().loadAvailableRegions(),
            ),
          ],
        ),
        body: BlocBuilder<OfflineMapsCubit, OfflineMapsState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                final cubit = context.read<OfflineMapsCubit>();
                await Future.wait([
                  cubit.loadRegions(),
                  cubit.loadAvailableRegions(),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (state.downloadingRegionName != null)
                    _DownloadingBanner(name: state.downloadingRegionName!),
                  _SectionHeader(title: 'Available from server'),
                  _AvailableSection(state: state),
                  const SizedBox(height: 16),
                  _SectionHeader(title: 'Downloaded'),
                  _DownloadedSection(state: state),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DownloadingBanner extends StatelessWidget {
  const _DownloadingBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Downloading $name…',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableSection extends StatelessWidget {
  const _AvailableSection({required this.state});

  final OfflineMapsState state;

  @override
  Widget build(BuildContext context) {
    switch (state.availableStatus) {
      case AvailableRegionsStatus.initial:
      case AvailableRegionsStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      case AvailableRegionsStatus.error:
        return _ErrorBlock(
          message: state.availableErrorMessage ?? 'Failed to load catalog',
          onRetry: () =>
              context.read<OfflineMapsCubit>().loadAvailableRegions(),
        );
      case AvailableRegionsStatus.loaded:
        if (state.availableRegions.isEmpty) {
          return _InfoBlock(
            icon: Icons.cloud_off_outlined,
            title: 'No regions on the server',
            body:
                'The gateway has not published any regions yet. Make sure the '
                'tile pipeline has run and try refreshing.',
          );
        }
        final downloadedRegionIds = state.regions
            .map((r) => r.regionId)
            .toSet();
        final isDownloading = state.status == OfflineMapsStatus.downloading;
        return Column(
          children: [
            for (final r in state.availableRegions)
              _AvailableRegionTile(
                region: r,
                alreadyDownloaded: downloadedRegionIds.contains(r.regionId),
                downloadDisabled: isDownloading,
                onDownload: () => context.read<OfflineMapsCubit>().downloadRegion(
                  regionId: r.regionId,
                  displayName: r.name,
                ),
              ),
          ],
        );
    }
  }
}

class _AvailableRegionTile extends StatelessWidget {
  const _AvailableRegionTile({
    required this.region,
    required this.alreadyDownloaded,
    required this.downloadDisabled,
    required this.onDownload,
  });

  final AvailableRegion region;
  final bool alreadyDownloaded;
  final bool downloadDisabled;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        alreadyDownloaded ? Icons.check_circle : Icons.public,
        color: alreadyDownloaded
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(region.name),
      subtitle: Text('${region.sizeMb} MB'),
      trailing: alreadyDownloaded
          ? Text(
              'Downloaded',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : FilledButton.tonalIcon(
              onPressed: downloadDisabled ? null : onDownload,
              icon: const Icon(Icons.download),
              label: const Text('Download'),
            ),
    );
  }
}

class _DownloadedSection extends StatelessWidget {
  const _DownloadedSection({required this.state});

  final OfflineMapsState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == OfflineMapsStatus.loading && state.regions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.regions.isEmpty) {
      return _InfoBlock(
        icon: Icons.map_outlined,
        title: 'No offline regions yet',
        body:
            'Tap Download next to a region above to use the map without '
            'an internet connection.',
      );
    }
    return Column(
      children: [
        for (final r in state.regions) _DownloadedRegionTile(region: r),
      ],
    );
  }
}

class _DownloadedRegionTile extends StatelessWidget {
  const _DownloadedRegionTile({required this.region});

  final OfflineRegion region;

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.map),
      title: Text(region.name),
      subtitle: Text(_formatBytes(region.sizeBytes)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.send_outlined),
            tooltip: 'Send to device',
            onPressed: () => _openSendToDevice(context, region.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, region.name, region.id),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String name, String id) {
    final cubit = context.read<OfflineMapsCubit>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete region?'),
        content: Text(
          'Remove "$name" from offline storage? The map data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.deleteRegion(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openSendToDevice(BuildContext context, String regionId) {
    final devicesFuture = context
        .read<DeviceCommBloc>()
        .getConnectedDeviceIds();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => FutureBuilder<List<ConnectedDeviceInfo>>(
        future: devicesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final devices = snapshot.data!;
          if (devices.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No devices connected. Connect a device (Wear or BLE) first.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Send to device',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: const Icon(Icons.devices),
                      title: Text(device.name ?? device.id),
                      subtitle: Text(device.id),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        context.read<DeviceCommBloc>().add(
                          SendMapRegionToDevice(
                            remoteId: device.id,
                            regionId: regionId,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
