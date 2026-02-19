import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/app/app_nav.dart';
import 'package:nav_e/core/domain/entities/saved_place.dart';
import 'package:nav_e/core/widgets/state_views.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_state.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      context.read<SavedPlacesCubit>().loadPlaces();
      _loaded = true;
    }
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
          title: const Text('Saved places'),
        ),
        body: BlocBuilder<SavedPlacesCubit, SavedPlacesState>(
          builder: (context, state) {
            if (state is SavedPlacesLoading) {
              return const AppLoadingState(message: 'Loading places...');
            }

            if (state is SavedPlacesError) {
              return AppErrorState(
                message: state.message,
                onRetry: () => context.read<SavedPlacesCubit>().loadPlaces(),
              );
            }

            if (state is SavedPlacesLoaded) {
              final places = state.places;
              if (places.isEmpty) {
                return AppEmptyState(
                  icon: Icons.bookmark_border,
                  title: 'No saved places yet.',
                  subtitle:
                      'Search for a location and tap "Save Location" to keep it here.',
                  actionLabel: 'Find a place',
                  onAction: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Use search to add your first place.'),
                      ),
                    );
                  },
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: places.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final place = places[index];
                  return Dismissible(
                    key: ValueKey('place_${place.id}_$index'),
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
                              title: const Text('Delete place'),
                              content: Text('Remove "${place.name}"?'),
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
                      if (place.id != null) {
                        final messenger = ScaffoldMessenger.of(context);
                        await context.read<SavedPlacesCubit>().deletePlace(
                          place.id!,
                        );
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Deleted "${place.name}"')),
                          );
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1,
                          ),
                          right: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1,
                          ),
                        ),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.place),
                        title: Text(place.name),
                        subtitle: Text(
                          [
                            if (place.address != null &&
                                place.address!.isNotEmpty)
                              place.address!,
                            '${place.lat.toStringAsFixed(5)}, ${place.lon.toStringAsFixed(5)}',
                          ].join('\n'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.visibility),
                          tooltip: 'Preview',
                          onPressed: () => _showPreview(context, place),
                        ),
                        onTap: () => _showPreview(context, place),
                      ),
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

  void _showPreview(BuildContext context, SavedPlace place) {
    AppNav.homeWithCoords(
      lat: place.lat,
      lon: place.lon,
      label: place.name,
      placeId: place.id?.toString(),
      zoom: 14,
    );
  }
}
