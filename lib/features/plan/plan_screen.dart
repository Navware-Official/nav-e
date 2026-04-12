import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/domain/entities/saved_route.dart';
import 'package:nav_e/core/theme/elevation.dart';
import 'package:nav_e/core/theme/spacing.dart';
import 'package:nav_e/features/saved_routes/cubit/saved_routes_cubit.dart';
import 'package:nav_e/features/saved_routes/cubit/saved_routes_state.dart';
import 'package:nav_e/features/saved_routes/route_enrichment.dart';

const int _previewCount = 6;

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _loaded = false;
  String _sourceFilter = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<SavedRoutesCubit>().loadRoutes();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          children: [
            // ── Header ──────────────────────────────────────────
            Text(
              'Plan a ride',
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Set your destination, pick a route, and go.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            // ── Search bar (tap to open search) ─────────────────
            const SizedBox(height: AppSpacing.lg),
            _SearchEntryBar(onTap: () => context.pushNamed('search')),

            // ── Quick actions ───────────────────────────────────
            const SizedBox(height: AppSpacing.lg),
            Text('Quick actions', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _QuickActionTile(
                    icon: Icons.map_outlined,
                    label: 'Plan on map',
                    onTap: () => context.go('/'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickActionTile(
                    icon: Icons.upload_file_outlined,
                    label: 'Import GPX',
                    onTap: () => context.pushNamed('importPreview'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickActionTile(
                    icon: Icons.bookmark_outline,
                    label: 'Saved places',
                    onTap: () => context.pushNamed('savedPlaces'),
                  ),
                ),
              ],
            ),

            // ── Your routes ─────────────────────────────────────
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your routes', style: textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.pushNamed('savedRoutes'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _SourceFilterChips(
              selected: _sourceFilter,
              onChanged: (v) => setState(() => _sourceFilter = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            _RoutesBody(sourceFilter: _sourceFilter),
          ],
        ),
      ),
    );
  }
}

// ── Search entry bar ──────────────────────────────────────────────────────────

class _SearchEntryBar extends StatelessWidget {
  const _SearchEntryBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14, // off-grid
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          boxShadow: AppElevation.level1(colorScheme.shadow),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Where are you heading?',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick action tile ─────────────────────────────────────────────────────────

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppSpacing.lg,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _SourceFilterChips extends StatelessWidget {
  const _SourceFilterChips({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = [('all', 'All'), ('gpx', 'GPX'), ('plan', 'Planned')];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (value, label) in filters)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(label),
                selected: selected == value,
                onSelected: (v) {
                  if (v) onChanged(value);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Routes list ───────────────────────────────────────────────────────────────

class _RoutesBody extends StatelessWidget {
  const _RoutesBody({required this.sourceFilter});

  final String sourceFilter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<SavedRoutesCubit, SavedRoutesState>(
      builder: (context, state) {
        if (state is SavedRoutesInitial || state is SavedRoutesLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is SavedRoutesError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              state.message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            ),
          );
        }

        if (state is SavedRoutesLoaded) {
          final pairs = List.generate(
            state.routes.length,
            (i) => (
              state.routes[i],
              i < state.enrichments.length
                  ? state.enrichments[i]
                  : const RouteEnrichment(),
            ),
          );

          final filtered = sourceFilter == 'all'
              ? pairs.take(_previewCount).toList()
              : pairs
                    .where((p) => p.$1.source == sourceFilter)
                    .take(_previewCount)
                    .toList();

          if (filtered.isEmpty) {
            return _EmptyRoutesState(sourceFilter: sourceFilter);
          }

          return Column(
            children: [
              for (final (route, enrichment) in filtered)
                _RouteCard(
                  route: route,
                  enrichment: enrichment,
                  onTap: () =>
                      context.pushNamed('savedRoutePreview', extra: route),
                ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyRoutesState extends StatelessWidget {
  const _EmptyRoutesState({required this.sourceFilter});

  final String sourceFilter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (icon, title, subtitle) = switch (sourceFilter) {
      'gpx' => (
        Icons.upload_file_outlined,
        'No GPX routes yet',
        'Import a GPX file to see it here.',
      ),
      'plan' => (
        Icons.map_outlined,
        'No planned routes yet',
        'Use "Plan on map" to create your first route.',
      ),
      _ => (
        Icons.route_outlined,
        'No saved routes',
        'Plan a route on the map or import a GPX file to get started.',
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppSpacing.xl,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Route card ────────────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.enrichment,
    required this.onTap,
  });

  final SavedRoute route;
  final RouteEnrichment enrichment;
  final VoidCallback onTap;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}h ${m}min' : '${h}h';
    }
    return '${minutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGpx = route.source == 'gpx';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              // Leading icon
              Container(
                width: AppSpacing.xxl,
                height: AppSpacing.xxl,
                decoration: BoxDecoration(
                  color: isGpx
                      ? colorScheme.tertiaryContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  isGpx ? Icons.insert_drive_file_outlined : Icons.route,
                  size: AppSpacing.lg,
                  color: isGpx
                      ? colorScheme.onTertiaryContainer
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            route.name,
                            style: textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _SourceBadge(isGpx: isGpx),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        if (enrichment.distanceKm != null) ...[
                          Icon(
                            Icons.straighten,
                            size: 14, // off-grid
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${enrichment.distanceKm!.toStringAsFixed(1)} km',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        if (enrichment.durationMinutes != null) ...[
                          Icon(
                            Icons.schedule,
                            size: 14, // off-grid
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _formatDuration(enrichment.durationMinutes!),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        const Spacer(),
                        Text(
                          _formatDate(route.createdAt),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Source badge ───────────────────────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.isGpx});

  final bool isGpx;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = isGpx
        ? colorScheme.tertiaryContainer
        : colorScheme.primaryContainer;
    final fg = isGpx
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2, // off-grid
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        isGpx ? 'GPX' : 'Plan',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
