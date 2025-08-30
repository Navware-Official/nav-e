import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc()
    : super(
        MapState(center: LatLng(52.3791, 4.9), zoom: 13.0, isReady: false),
      ) {
    on<MapMoved>((event, emit) {
      emit(state.copyWith(center: event.center, zoom: event.zoom));
    });

    on<MapInitialized>((event, emit) {
      emit(state.copyWith(isReady: true));
    });

    on<ToggleFollowUser>((event, emit) {
      emit(state.copyWith(followUser: event.follow));
    });
  }
}
