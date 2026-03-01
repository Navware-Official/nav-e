import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/domain/entities/saved_route.dart';
import 'package:nav_e/core/widgets/state_views.dart';
import 'package:nav_e/features/saved_routes/cubit/saved_routes_cubit.dart';
import 'package:nav_e/features/saved_routes/cubit/saved_routes_state.dart';
import 'package:nav_e/features/saved_routes/route_enrichment.dart';

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({super.key});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    // Defer load until after the first frame so the screen opens immediately
    // and shows "Loading routes..."; heavy getAll() runs after that.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SavedRoutesCubit>().loadRoutes();
    });
  }

  void _openImportScreen(BuildContext context) {
    context.pushNamed('importPreview');
  }

  @override
  Widget build(BuildContext context) {
    return HeroMode(
      enabled: false,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Saved routes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Import GPX',
              onPressed: () => _openImportScreen(context),
            ),
          ],
        ),
        body: BlocBuilder<SavedRoutesCubit, SavedRoutesState>(
          builder: (context, state) {
            if (state is SavedRoutesInitial || state is SavedRoutesLoading) {
              return const AppLoadingState(message: 'Loading routes...');
            }

            if (state is SavedRoutesError) {
              return AppErrorState(
                message: state.message,
                onRetry: () => context.read<SavedRoutesCubit>().loadRoutes(),
              );
            }

            if (state is SavedRoutesLoaded) {
              final routes = state.routes;
              if (routes.isEmpty) {
                return AppEmptyState(
                  icon: Icons.route,
                  title: 'No saved routes yet.',
                  subtitle:
                      'Import a GPX file or save a route from the plan screen.',
                  actionLabel: 'Import GPX',
                  onAction: () => _openImportScreen(context),
                );
              }

              final enrichments = state.enrichments;

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: routes.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final route = routes[index];
                  final enrichment = enrichments[index];
                  final stableKey = route.id != null
                      ? 'route_${route.id}'
                      : 'route_${route.createdAt.millisecondsSinceEpoch}_${route.name}';
                  return Dismissible(
                    key: ValueKey(stableKey),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Theme.of(context).colorScheme.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        Icons.delete,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete route'),
                              content: Text('Remove "${route.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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
                    onDismissed: (_) async {
                      if (route.id != null) {
                        final messenger = ScaffoldMessenger.of(context);
                        await context.read<SavedRoutesCubit>().deleteRoute(
                          route.id!,
                        );
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Deleted "${route.name}"')),
                          );
                        }
                      }
                    },
                    child: ListTile(
                      leading: const Icon(Icons.route),
                      title: Text(route.name),
                      subtitle: Text(
                        _subtitleText(route, enrichment),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () =>
                          context.pushNamed('savedRoutePreview', extra: route),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _subtitleText(SavedRoute route, RouteEnrichment e) {
    final parts = <String>['${route.source} · ${_formatDate(route.createdAt)}'];
    if (e.distanceKm != null) {
      parts.add('${e.distanceKm!.toStringAsFixed(1)} km');
    }
    if (e.durationMinutes != null) {
      parts.add('${e.durationMinutes} min');
    }
    if (e.country != null && e.country!.isNotEmpty) {
      parts.add(e.country!);
    }
    return parts.join(' · ');
  }
}
