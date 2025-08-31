import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final List<Marker> markers;
  final void Function(dynamic position, bool hasGesture)? onMapInteraction;

  const MapWidget({
    super.key,
    required this.mapController,
    required this.markers,
    this.onMapInteraction,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MapBloc, MapState>(
      listenWhen: (prev, curr) =>
          curr.isReady &&
          (prev.center != curr.center || prev.zoom != curr.zoom),
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          mapController.move(state.center, state.zoom);
        });
      },
      builder: (context, state) {
        final src = state.source;

        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: state.center,
            initialZoom: state.zoom,
            onMapReady: () {
              if (!state.isReady) {
                context.read<MapBloc>().add(MapInitialized());
              }
            },
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture) {
                context.read<MapBloc>().add(ToggleFollowUser(false));
              }
              final c = pos.center, z = pos.zoom;
              if (c != state.center || z != state.zoom) {
                context.read<MapBloc>().add(MapMoved(c, z));
              }
              onMapInteraction?.call(pos, hasGesture);
            },
          ),
          children: [
            if (src != null)
              TileLayer(
                urlTemplate: _withQueryParams(src.urlTemplate, src.queryParams),
                subdomains: src.subdomains,
                minZoom: src.minZoom.toDouble(),
                maxZoom: src.maxZoom.toDouble(),
                userAgentPackageName: 'nav_e.navware',
                additionalOptions: Map<String, String>.from(
                  src.queryParams ?? const {},
                ),
                tileProvider: NetworkTileProvider(
                  headers: Map<String, String>.from(src.headers ?? const {}),
                ),
              ),

            MarkerLayer(markers: markers),

            if (src?.attribution != null)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: RichAttributionWidget(
                    attributions: [TextSourceAttribution(src!.attribution!)],
                    alignment: AttributionAlignment.bottomRight,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _withQueryParams(String template, Map<String, String>? qp) {
    if (qp == null || qp.isEmpty) return template;
    final sep = template.contains('?') ? '&' : '?';
    final suffix = qp.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    return '$template$sep$suffix';
  }
}
