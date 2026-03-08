import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/domain/entities/saved_route.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _ActionCardsRow(
            onPlanOnMap: () => context.go('/'),
            onImport: () => context.pushNamed('importPreview'),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your routes', style: textTheme.headlineSmall),
              TextButton(
                onPressed: () => context.pushNamed('savedRoutes'),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _SourceFilterChips(
            selected: _sourceFilter,
            onChanged: (v) => setState(() => _sourceFilter = v),
          ),
          const SizedBox(height: 10),
          _RoutesBody(sourceFilter: _sourceFilter),
        ],
      ),
    );
  }
}

// ── Action cards ────────────────────────────────────────────────────────────

class _ActionCardsRow extends StatelessWidget {
  const _ActionCardsRow({required this.onPlanOnMap, required this.onImport});

  final VoidCallback onPlanOnMap;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.map_outlined,
            label: 'Plan on map',
            onTap: onPlanOnMap,
            primary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.upload_file_outlined,
            label: 'Import GPX',
            onTap: onImport,
            primary: false,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = primary
        ? colorScheme.primaryContainer
        : colorScheme.secondaryContainer;
    final fg = primary
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSecondaryContainer;

    return Card(
      color: bg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 34, color: fg),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter chips ────────────────────────────────────────────────────────────

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
              padding: const EdgeInsets.only(right: 8),
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

// ── Routes list ─────────────────────────────────────────────────────────────

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
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is SavedRoutesError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              state.message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            ),
          );
        }

        if (state is SavedRoutesLoaded) {
          // Build aligned (route, enrichment) pairs then filter by source.
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
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                _emptyMessage(sourceFilter),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
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

  String _emptyMessage(String filter) {
    switch (filter) {
      case 'gpx':
        return 'No GPX routes yet. Import a GPX file to get started.';
      case 'plan':
        return 'No planned routes yet. Use "Plan on map" to create one.';
      default:
        return 'No saved routes yet. Import a GPX or plan a route on the map.';
    }
  }
}

// ── Route card ──────────────────────────────────────────────────────────────

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
    final badgeBg = isGpx
        ? colorScheme.tertiaryContainer
        : colorScheme.primaryContainer;
    final badgeFg = isGpx
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.route, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      route.name,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isGpx ? 'GPX' : 'Plan',
                      style: textTheme.labelSmall?.copyWith(color: badgeFg),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (enrichment.distanceKm != null) ...[
                    _StatPill(
                      '${enrichment.distanceKm!.toStringAsFixed(1)} km',
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (enrichment.durationMinutes != null) ...[
                    _StatPill(_formatDuration(enrichment.durationMinutes!)),
                    const SizedBox(width: 6),
                  ],
                  const Spacer(),
                  Text(
                    _formatDate(route.createdAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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

class _StatPill extends StatelessWidget {
  const _StatPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
