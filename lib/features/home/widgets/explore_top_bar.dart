import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';
import 'package:nav_e/features/map_layers/data/data_layer_registry.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';
import 'package:nav_e/features/search/bloc/search_bloc.dart';
import 'package:nav_e/features/search/search_screen.dart';
import 'package:nav_e/widgets/search_bar_widget.dart';

/// Top bar for the Explore tab: search field (no menu) + horizontal filter chips
/// for data layers (e.g. Parking).
class ExploreTopBar extends StatelessWidget {
  const ExploreTopBar({super.key, required this.onResultSelected});

  final ValueChanged<GeocodingResult> onResultSelected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Hero(
                tag: 'searchBarHero',
                child: SearchBarWidget(
                  hintText: 'Search for a place',
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (ctx) =>
                              SearchBloc(ctx.read<IGeocodingRepository>()),
                          child: const SearchScreen(),
                        ),
                      ),
                    );
                    if (result != null) {
                      onResultSelected(result);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              _FilterChips(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final definitions = getDataLayerDefinitions();
    if (definitions.isEmpty) return const SizedBox.shrink();

    return BlocBuilder<MapBloc, MapState>(
      buildWhen: (prev, curr) =>
          prev.enabledDataLayerIds != curr.enabledDataLayerIds,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: definitions.map((def) {
              final isSelected = state.enabledDataLayerIds.contains(def.id);
              final textTheme = Theme.of(context).textTheme;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(def.name, style: textTheme.labelLarge),
                  selected: isSelected,
                  onSelected: (_) {
                    context.read<MapBloc>().add(ToggleDataLayer(def.id));
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
