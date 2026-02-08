import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:nav_e/core/data/map_adapter.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/features/map_layers/models/marker_model.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';
import 'package:nav_e/features/map_layers/presentation/map_adapters/maplibre_map_adapter.dart';

class MapWidget extends StatefulWidget {
  final List<MarkerModel> markers;
  final void Function(LatLng latlng)? onMapTap;

  const MapWidget({super.key, required this.markers, this.onMapTap});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  MapAdapter? _adapter;
  int _lastResetBearingTick = 0;

  @override
  void initState() {
    super.initState();
  }

  void _ensureAdapter(MapState state) {
    // Create adapter if not yet created
    if (_adapter == null) {
      _adapter = MapLibreMapAdapter();
      debugPrint('[MapWidget] MapLibre adapter created');
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

    return MultiBlocListener(
      listeners: [
        BlocListener<LocationBloc, LocationState>(
          listenWhen: (prev, curr) => curr.position != prev.position,
          listener: (context, locState) {
            if (!context.mounted) return;
            final pos = locState.position;
            if (pos == null) return;
            final mapState = mapBloc.state;
            if (!mapState.followUser) return;
            mapBloc.add(MapMoved(pos, mapState.zoom, force: true));
          },
        ),
      ],
      child: BlocConsumer<MapBloc, MapState>(
        buildWhen: (prev, curr) =>
            prev.source != curr.source ||
            prev.isReady != curr.isReady ||
            prev.polylines != curr.polylines,
        listenWhen: (prev, curr) =>
            curr.isReady &&
            (prev.center != curr.center ||
                prev.zoom != curr.zoom ||
                prev.polylines != curr.polylines ||
                prev.followUser != curr.followUser ||
                prev.resetBearingTick != curr.resetBearingTick ||
                curr.autoFit),
        listener: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!context.mounted) return;
            if (state.resetBearingTick != _lastResetBearingTick) {
              _lastResetBearingTick = state.resetBearingTick;
              if (_adapter != null) {
                debugPrint('[MapWidget] resetBearing');
                _adapter!.resetBearing();
              }
            }
            // Only move the camera automatically when the map is in follow-user
            // mode, or when an explicit auto-fit was requested. This prevents
            // overriding user gestures (panning/zooming) which caused jitter.
            if (state.autoFit && state.polylines.isNotEmpty) {
              try {
                debugPrint(
                  '[MapWidget] autoFit | polylines=${state.polylines.length}',
                );
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
              debugPrint(
                '[MapWidget] followUser move | state=${state.center},${state.zoom} '
                'adapter=${_adapter?.currentCenter},${_adapter?.currentZoom}',
              );
              if (_adapter != null &&
                  (_adapter!.currentCenter != state.center ||
                      _adapter!.currentZoom != state.zoom)) {
                _adapter!.moveCamera(state.center, state.zoom);
              }
            }
          });
        },
        builder: (context, state) {
          // Ensure adapter is created
          _ensureAdapter(state);

          if (_adapter == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return KeyedSubtree(
            key: const ValueKey('maplibre_map'),
            child: _adapter!.buildMap(
              source: state.source,
              center: state.center,
              zoom: state.zoom,
              markers: widget.markers,
              polylines: [...state.polylines],
              onMapReady: () {
                if (!state.isReady) {
                  mapBloc.add(MapInitialized());
                }
              },
              onPositionChanged: (center, zoom) {
                debugPrint('[MapWidget] onPositionChanged $center $zoom');
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
            ),
          );
        },
      ),
    );
  }
}
