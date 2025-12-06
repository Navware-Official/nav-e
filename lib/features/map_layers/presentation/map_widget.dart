import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:nav_e/core/data/map_adapter.dart';
import 'package:nav_e/core/data/map_adapter_factory.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';
import 'package:nav_e/features/map_layers/presentation/map_adapters/legacy_map_adapter.dart';

class MapWidget extends StatefulWidget {
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
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  MapAdapter? _adapter;
  bool _lastUseMapLibre = false;

  @override
  void initState() {
    super.initState();
    // Adapter will be created in build based on state
  }

  void _ensureAdapter(MapState state) {
    // Recreate adapter if preference changed or not yet created
    if (_adapter == null || _lastUseMapLibre != state.useMapLibre) {
      _adapter?.dispose();
      _adapter = MapAdapterFactory.create(
        source: state.source,
        useMapLibre: state.useMapLibre,
      );
      _lastUseMapLibre = state.useMapLibre;
    }
  }

  @override
  void dispose() {
    _adapter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapBloc = context.read<MapBloc>();

    return BlocConsumer<MapBloc, MapState>(
      buildWhen: (prev, curr) => prev.useMapLibre != curr.useMapLibre || prev.source != curr.source || prev.isReady != curr.isReady,
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
              // Use adapter instead of direct controller
              _adapter?.fitBounds(
                coordinates: coords,
                padding: pad,
                maxZoom: 17,
              );
            } catch (e) {
              // ignore
            } finally {
              // inform bloc that autoFit has been handled
              context.read<MapBloc>().add(MapAutoFitDone());
            }
          } else if (state.followUser) {
            // Only move the camera to follow the user when followUser flag is true.
            // Use adapter instead of direct controller
            if (_adapter != null && (_adapter!.currentCenter != state.center || _adapter!.currentZoom != state.zoom)) {
              _adapter!.moveCamera(state.center, state.zoom);
            }
          }
        });
      },
      builder: (context, state) {
        // Ensure adapter is created/updated based on current state
        if (!state.isReady) {
          _adapter = MapAdapterFactory.create(
            source: state.source,
            useMapLibre: state.useMapLibre,
          );
          _lastUseMapLibre = state.useMapLibre;
        } else {
          _ensureAdapter(state);
        }
        
        final src = state.source;

        // For legacy adapter, we still need to use the passed-in controller
        // This maintains backward compatibility
        if (_adapter is LegacyMapAdapter) {
          return RepaintBoundary(
            child: FlutterMap(
              mapController: widget.mapController,
              options: MapOptions(
                initialCenter: state.center,
                initialZoom: state.zoom,
                onTap: (tapPos, latlng) {
                  widget.onMapTap?.call(latlng);
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
                  widget.onMapInteraction?.call(pos, hasGesture);
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
                if ((widget.polylines.isNotEmpty || state.polylines.isNotEmpty))
                  PolylineLayer(
                    polylines: [
                      ...widget.polylines,
                      ...state.polylines.map((m) => Polyline(
                            points: m.points,
                            color: Color(m.colorArgb),
                            strokeWidth: m.strokeWidth,
                          )),
                    ],
                  ),
                MarkerLayer(markers: widget.markers),
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
        }

        // For other adapters (e.g., MapLibre), use the adapter's buildMap
        if (_adapter == null) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return _adapter!.buildMap(
          source: src,
          center: state.center,
          zoom: state.zoom,
          markers: widget.markers.map((m) => m as Widget).toList(),
          polylines: [...state.polylines],
          onMapReady: () {
            if (!state.isReady) {
              mapBloc.add(MapInitialized());
            }
          },
          onPositionChanged: (center, zoom) {
            if (center != state.center || zoom != state.zoom) {
              mapBloc.add(MapMoved(center, zoom));
            }
          },
          onUserGesture: (hasGesture) {
            if (hasGesture) {
              mapBloc.add(ToggleFollowUser(false));
            }
          },
          onMapTap: widget.onMapTap,
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
