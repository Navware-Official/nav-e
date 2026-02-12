import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:nav_e/core/domain/repositories/offline_regions_repository.dart';
import 'package:nav_e/features/offline_maps/cubit/offline_maps_cubit.dart';
import 'package:nav_e/features/offline_maps/cubit/offline_maps_state.dart';
import 'package:nav_e/features/offline_maps/presentation/widgets/download_region_sheet.dart';
import 'package:nav_e/features/offline_maps/presentation/widgets/select_region_sheet.dart';
import 'package:nav_e/features/offline_maps/presentation/widgets/offline_region_list_tile.dart';

class OfflineMapsScreen extends StatelessWidget {
  const OfflineMapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          OfflineMapsCubit(context.read<IOfflineRegionsRepository>())
            ..loadRegions(),
      child: const _OfflineMapsView(),
    );
  }
}

class _OfflineMapsView extends StatelessWidget {
  const _OfflineMapsView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineMapsCubit, OfflineMapsState>(
      listenWhen: (prev, curr) =>
          prev.status == OfflineMapsStatus.downloading &&
          (curr.status == OfflineMapsStatus.loaded ||
              curr.status == OfflineMapsStatus.error),
      listener: (context, state) {
        if (state.status == OfflineMapsStatus.loaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Region downloaded')),
          );
        } else if (state.status == OfflineMapsStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Offline maps'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'manual') _openDownloadSheet(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'manual',
                child: Text('Add manually (enter bounds)'),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<OfflineMapsCubit, OfflineMapsState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.regions != curr.regions ||
            prev.errorMessage != curr.errorMessage ||
            prev.downloadProgress != curr.downloadProgress ||
            prev.downloadTotal != curr.downloadTotal ||
            prev.downloadingRegionName != curr.downloadingRegionName,
        builder: (context, state) {
          final isDownloading = state.status == OfflineMapsStatus.downloading;
          if (state.status == OfflineMapsStatus.loading &&
              state.regions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && state.regions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          context.read<OfflineMapsCubit>().loadRegions(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final regions = state.regions;
          Widget listOrEmpty;
          if (regions.isEmpty && !isDownloading) {
            listOrEmpty = Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No offline regions yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Download a region to use maps without internet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else {
            listOrEmpty = ListView.builder(
              itemCount: regions.length,
              itemBuilder: (context, index) {
                final region = regions[index];
                return OfflineRegionListTile(
                  region: region,
                  onDelete: () =>
                      _confirmDelete(context, region.name, region.id),
                );
              },
            );
          }
          if (isDownloading) {
            final name = state.downloadingRegionName ?? 'region';
            final hasProgress =
                state.downloadTotal > 0 && state.downloadTotal >= state.downloadProgress;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  elevation: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Downloading $name…',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (hasProgress) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: state.downloadTotal > 0
                                ? state.downloadProgress /
                                    state.downloadTotal
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${state.downloadProgress} / ${state.downloadTotal} tiles (zoom ${state.downloadZoom})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(child: listOrEmpty),
              ],
            );
          }
          return listOrEmpty;
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddRegion(context),
        icon: const Icon(Icons.add),
        label: const Text('Add region'),
      ),
    ),
    );
  }

  Future<void> _openAddRegion(BuildContext context) async {
    final selected = await showSelectRegionSheetResult(context);
    if (!context.mounted) return;
    final cubit = context.read<OfflineMapsCubit>();
    if (selected != null) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: DownloadRegionSheet(
            initialBbox: selected.bbox,
            initialName: selected.name,
          ),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const DownloadRegionSheet(),
        ),
      );
    }
  }

  void _openDownloadSheet(BuildContext context) {
    final cubit = context.read<OfflineMapsCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const DownloadRegionSheet(),
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
}
