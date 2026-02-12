import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:nav_e/core/bloc/location_bloc.dart';

import 'package:nav_e/core/data/map_adapter.dart';
import 'package:nav_e/features/map_layers/data/data_layer_registry.dart';
import 'package:nav_e/features/offline_maps/data/offline_map_style_resolver.dart';
import 'package:nav_e/features/map_layers/models/marker_model.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';
import 'package:nav_e/features/map_layers/presentation/map_adapters/maplibre_map_adapter.dart';

class MapWidget extends StatefulWidget {
  final List<MarkerModel> markers;
  final void Function(LatLng latlng)? onMapTap;
  final void Function(LatLng latlng)? onMapLongPress;
  final void Function(String layerId, Map<String, dynamic> properties)?
  onDataLayerFeatureTap;

  const MapWidget({
    super.key,
    required this.markers,
    this.onMapTap,
    this.onMapLongPress,
    this.onDataLayerFeatureTap,
  });

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
            prev.polylines != curr.polylines ||
            prev.enabledDataLayerIds != curr.enabledDataLayerIds ||
            prev.markerFillColorArgb != curr.markerFillColorArgb ||
            prev.markerStrokeColorArgb != curr.markerStrokeColorArgb ||
            prev.defaultPolylineColorArgb != curr.defaultPolylineColorArgb ||
            prev.defaultPolylineWidth != curr.defaultPolylineWidth,
        listenWhen: (prev, curr) =>
            curr.isReady &&
            (prev.center != curr.center ||
                prev.zoom != curr.zoom ||
                prev.tilt != curr.tilt ||
                prev.bearing != curr.bearing ||
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
              // Use tolerance to avoid feedback loop: map reports position -> we move ->
              // map reports again (slight diff) -> we move again -> freeze/jitter.
              if (_adapter == null) return;
              const centerTolerance = 1e-6;
              const zoomTolerance = 0.001;
              final centerMatch =
                  (_adapter!.currentCenter.latitude - state.center.latitude).abs() < centerTolerance &&
                  (_adapter!.currentCenter.longitude - state.center.longitude).abs() < centerTolerance;
              final zoomMatch =
                  (_adapter!.currentZoom - state.zoom).abs() < zoomTolerance;
              final tiltMatch = (_adapter!.currentTilt - state.tilt).abs() < 0.01;
              final bearingMatch = (_adapter!.currentBearing - state.bearing).abs() < 0.01;
              if (centerMatch && zoomMatch && tiltMatch && bearingMatch) {
                return;
              }
              _adapter!.moveCamera(
                state.center,
                state.zoom,
                tilt: state.tilt,
                bearing: state.bearing,
              );
            }
          });
        },
        builder: (context, state) {
          final isOffline =
              state.source?.urlTemplate.startsWith('offline://') == true;
          if (isOffline) {
            final regionId = state.source!.urlTemplate.replaceFirst(
              'offline://',
              '',
            );
            final resolver = context.read<OfflineMapStyleResolver>();
            return FutureBuilder<String?>(
              key: ValueKey('offline_$regionId'),
              future: resolver.getStyleString(regionId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final styleOverride = snapshot.data;
                if (styleOverride == null) {
                  return const Center(child: Text('Offline region not found'));
                }
                return _buildMapContent(
                  context,
                  state,
                  mapBloc,
                  styleStringOverride: styleOverride,
                );
              },
            );
          }
          return _buildMapContent(context, state, mapBloc);
        },
      ),
    );
  }

  Widget _buildMapContent(
    BuildContext context,
    MapState state,
    MapBloc mapBloc, {
    String? styleStringOverride,
  }) {
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
          if (center != state.center || zoom != state.zoom) {
            mapBloc.add(MapMoved(center, zoom));
          }
        },
        onUserGesture: (hasGesture) {
          if (hasGesture) {
            mapBloc.add(ToggleFollowUser(false));
          }
        },
        onCameraIdle: () {
          if (!context.mounted) return;
          final mapState = mapBloc.state;
          if (!mapState.followUser) return;
          final location = context.read<LocationBloc>().state.position;
          if (location == null || _adapter == null) return;
          const thresholdMeters = 25.0;
          final distance = const Distance().distance(
            _adapter!.currentCenter,
            location,
          );
          if (distance > thresholdMeters) {
            mapBloc.add(ToggleFollowUser(false));
          }
        },
        onMapTap: widget.onMapTap,
        onMapLongPress: widget.onMapLongPress,
        enabledDataLayerIds: state.enabledDataLayerIds,
        dataLayerDefinitions: getDataLayerDefinitions(),
        markerFillColorArgb: state.markerFillColorArgb,
        markerStrokeColorArgb: state.markerStrokeColorArgb,
        defaultPolylineColorArgb: state.defaultPolylineColorArgb,
        defaultPolylineWidth: state.defaultPolylineWidth,
        onDataLayerFeatureTap: widget.onDataLayerFeatureTap,
        styleStringOverride: styleStringOverride,
      ),
    );
  }
}
