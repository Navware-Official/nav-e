import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';

class MapSourceSettingsSection extends StatelessWidget {
  const MapSourceSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        final sources = state.available ?? [];
        final current = state.source;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Map Source',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            if (sources.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No map sources available.'),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: current?.id,
                  items: sources
                      .map(
                        (source) => DropdownMenuItem<String>(
                          value: source.id,
                          child: Text(source.name),
                        ),
                      )
                      .toList(),
                  onChanged: (selectedId) {
                    if (selectedId != null && selectedId != current?.id) {
                      context.read<MapBloc>().add(MapSourceChanged(selectedId));
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
