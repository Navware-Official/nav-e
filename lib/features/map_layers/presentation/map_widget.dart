import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final void Function(dynamic position, bool hasGesture)? onMapInteraction;
  // Called when the user taps the map. Provides the tapped LatLng.
  final void Function(LatLng latlng)? onMapTap;

  const MapWidget({
    super.key,
    required this.mapController,
    required this.markers,
    this.onMapInteraction,
    this.onMapTap,
    this.polylines = const [],
  });

  @override
  Widget build(BuildContext context) {
    final mapBloc = context.read<MapBloc>();

    return BlocConsumer<MapBloc, MapState>(
      listenWhen: (prev, curr) => curr.isReady && (prev.center != curr.center || prev.zoom != curr.zoom || prev.polylines != curr.polylines || curr.autoFit),
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;
          // Only move the camera automatically when the map is in follow-user
          // mode, or when an explicit auto-fit was requested. This prevents
          // overriding user gestures (panning/zooming) which caused jitter.
          if (state.autoFit && state.polylines.isNotEmpty) {
            try {
              final coords = state.polylines.expand((p) => p.points).toList();
              final mq = MediaQuery.of(context);
              final pad = EdgeInsets.only(
                left: 12,
                right: 12,
                top: mq.padding.top + 88,
                bottom: mq.padding.bottom + 220,
              );
              final fit = CameraFit.coordinates(coordinates: coords, maxZoom: 17, padding: pad);
              mapController.fitCamera(fit);
            } catch (e) {
              // ignore
            } finally {
              // inform bloc that autoFit has been handled
              context.read<MapBloc>().add(MapAutoFitDone());
            }
          } else if (state.followUser) {
            // Only move the camera to follow the user when followUser flag is true.
            try {
              final cam = mapController.camera;
              if (cam.center != state.center || cam.zoom != state.zoom) {
                mapController.move(state.center, state.zoom);
              }
            } catch (_) {
              mapController.move(state.center, state.zoom);
            }
          }
        });
      },
      builder: (context, state) {
        final src = state.source;

        return RepaintBoundary(
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: state.center,
              initialZoom: state.zoom,
              // Forward taps to the optional onMapTap callback so parent
              // widgets (e.g. PlanRoute) can implement 'pick on map'.
              onTap: (tapPos, latlng) {
                onMapTap?.call(latlng);
              },
              onMapReady: () {
                if (!state.isReady) {
                  mapBloc.add(MapInitialized());
                }
              },
              onPositionChanged: (pos, hasGesture) {
                if (!context.mounted) return;

                if (hasGesture) {
                  mapBloc.add(ToggleFollowUser(false));
                }
                final c = pos.center, z = pos.zoom;
                if (c != state.center || z != state.zoom) {
                  mapBloc.add(MapMoved(c, z));
                }
                onMapInteraction?.call(pos, hasGesture);
              },
            ),
              children: [
              if (src != null)
                TileLayer(
                  urlTemplate: _withQueryParams(
                    src.urlTemplate,
                    src.queryParams,
                  ),
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

              // Render polylines from both the widget and the MapBloc state
              if ((polylines.isNotEmpty || state.polylines.isNotEmpty))
                PolylineLayer(
                  polylines: [
                    ...polylines,
                    // convert lightweight PolylineModel to widget Polyline
                    ...state.polylines.map((m) => Polyline(
                          points: m.points,
                          color: Color(m.colorArgb),
                          strokeWidth: m.strokeWidth,
                        )),
                  ],
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
          ),
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
