import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nav_e/core/domain/repositories/map_source_repository.dart';
import 'map_events.dart';
import 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final IMapSourceRepository sources;
  static const String _prefKeyMapLibre = 'use_map_libre';

  MapBloc(this.sources)
    : super(
        MapState(center: LatLng(52.3791, 4.9), zoom: 13.0, isReady: false),
      ) {
    _loadMapAdapterPreference();
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
    on<MapSourceChanged>(_onSourceChanged, transformer: restartable());
    on<ToggleMapAdapter>(_onToggleMapAdapter);
  }

  Future<void> _loadMapAdapterPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final useMapLibre = prefs.getBool(_prefKeyMapLibre) ?? false;
    add(ToggleMapAdapter(useMapLibre));
  }

  void _onMoved(MapMoved event, Emitter<MapState> emit) {
    emit(state.copyWith(center: event.center, zoom: event.zoom));
  }

  void _onToggleFollow(ToggleFollowUser event, Emitter<MapState> emit) {
    emit(state.copyWith(followUser: event.follow));
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

  Future<void> _onToggleMapAdapter(
    ToggleMapAdapter event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(useMapLibre: event.useMapLibre));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyMapLibre, event.useMapLibre);
  }

  EventTransformer<T> _throttle<T>(Duration d) {
    return (events, mapper) => events.throttle(d).asyncExpand(mapper);
  }
}
