import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/domain/entities/saved_route.dart';
import 'package:nav_e/features/saved_routes/cubit/saved_routes_cubit.dart';
import 'package:nav_e/features/saved_routes/cubit/saved_routes_state.dart';
import 'package:nav_e/features/saved_routes/route_enrichment.dart';

const int _previewCount = 5;

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _loaded = false;

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

  void _openImport(BuildContext context) {
    context.pushNamed('importPreview');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import route'),
              subtitle: const Text('Import a GPX file'),
              onTap: () => _openImport(context),
            ),
          ),
          const SizedBox(height: 24),
          _SavedRoutesSection(),
        ],
      ),
    );
  }
}

class _SavedRoutesSection extends StatelessWidget {
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
