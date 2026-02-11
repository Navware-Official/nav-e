import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:stream_transform/stream_transform.dart';

import 'package:nav_e/core/domain/repositories/map_source_repository.dart';
import 'map_events.dart';
import 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final IMapSourceRepository sources;

  MapBloc(this.sources)
    : super(
        MapState(
          center: const LatLng(52.3791, 4.9),
          zoom: 13.0,
          isReady: false,
        ),
      ) {
    on<MapInitialized>((event, emit) async {
      try {
        final current = await sources.getCurrent();
        final all = await sources.getAll();
        emit(
          state.copyWith(
            isReady: true,
            source: current,
            available: all,
            error: null,
          ),
        );
      } catch (e) {
        emit(state.copyWith(isReady: true, error: e));
      }
    });
    on<MapMoved>(
      _onMoved,
      transformer: _throttle(const Duration(milliseconds: 120)),
    );
    on<ReplacePolylines>(_onReplacePolylines);
    on<MapAutoFitDone>(_onAutoFitDone);
    on<ToggleFollowUser>(_onToggleFollow);
    on<ResetBearing>(_onResetBearing);
    on<MapSourceChanged>(_onSourceChanged, transformer: restartable());
    on<ToggleDataLayer>(_onToggleDataLayer);
    on<SetMapStyleConfig>(_onSetMapStyleConfig);
    on<ResetMapStyleConfig>(_onResetMapStyleConfig);
  }

  void _onMoved(MapMoved event, Emitter<MapState> emit) {
    // When followUser is true we are driving the camera from state (e.g.
    // "go to my location"); ignore camera position reports so we don't
    // overwrite the target and prevent the move from completing.
    debugPrint(
      '[MapBloc] MapMoved | force=${event.force} followUser=${state.followUser} '
      'from=${state.center},${state.zoom} to=${event.center},${event.zoom}',
    );
    if (state.followUser && !event.force) return;
    emit(
      state.copyWith(
        center: event.center,
        zoom: event.zoom,
        tilt: event.tilt ?? state.tilt,
        bearing: event.bearing ?? state.bearing,
      ),
    );
  }

  void _onToggleFollow(ToggleFollowUser event, Emitter<MapState> emit) {
    emit(state.copyWith(followUser: event.follow));
  }

  void _onResetBearing(ResetBearing event, Emitter<MapState> emit) {
    emit(state.copyWith(resetBearingTick: state.resetBearingTick + 1));
  }

  Future<void> _onSourceChanged(
    MapSourceChanged event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(loadingSource: true, error: null));
    try {
      await sources.setCurrent(event.sourceId);
      final src = await sources.getCurrent();
      emit(state.copyWith(source: src, loadingSource: false));
    } catch (e) {
      emit(state.copyWith(loadingSource: false, error: e));
    }
  }

  void _onReplacePolylines(ReplacePolylines event, Emitter<MapState> emit) {
    emit(state.copyWith(polylines: event.polylines, autoFit: event.fit));
  }

  void _onAutoFitDone(MapAutoFitDone event, Emitter<MapState> emit) {
    // clear the autoFit flag after the widget performed the fit
    if (state.autoFit) emit(state.copyWith(autoFit: false));
  }

  void _onToggleDataLayer(ToggleDataLayer event, Emitter<MapState> emit) {
    final next = Set<String>.from(state.enabledDataLayerIds);
    if (next.contains(event.layerId)) {
      next.remove(event.layerId);
    } else {
      next.add(event.layerId);
    }
    emit(state.copyWith(enabledDataLayerIds: next));
  }

  void _onSetMapStyleConfig(SetMapStyleConfig event, Emitter<MapState> emit) {
    emit(state.copyWith(
      defaultPolylineColorArgb:
          event.defaultPolylineColorArgb ?? state.defaultPolylineColorArgb,
      defaultPolylineWidth:
          event.defaultPolylineWidth ?? state.defaultPolylineWidth,
      markerFillColorArgb:
          event.markerFillColorArgb ?? state.markerFillColorArgb,
      markerStrokeColorArgb:
          event.markerStrokeColorArgb ?? state.markerStrokeColorArgb,
    ));
  }

  void _onResetMapStyleConfig(
    ResetMapStyleConfig event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(clearStyleOverrides: true));
  }

  EventTransformer<T> _throttle<T>(Duration d) {
    return (events, mapper) => events.throttle(d).asyncExpand(mapper);
  }
}
