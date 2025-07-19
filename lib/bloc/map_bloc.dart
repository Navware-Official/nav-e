import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

abstract class MapEvent {}

class MapMoved extends MapEvent {
  final LatLng center;
  final double zoom;

  MapMoved(this.center, this.zoom);
}

class MapInitialized extends MapEvent {}

class MapState {
  final LatLng center;
  final double zoom;
  final bool isReady;

  MapState({
    required this.center,
    required this.zoom,
    required this.isReady,
  });

  MapState copyWith({
    LatLng? center,
    double? zoom,
    bool? isReady,
  }) {
    return MapState(
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      isReady: isReady ?? this.isReady,
    );
  }
}

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc()
      : super(MapState(
          center: LatLng(52.3791, 4.9003), // Default: Amsterdam
          zoom: 13.0,
          isReady: false,
        )) {
    on<MapMoved>((event, emit) {
      emit(state.copyWith(center: event.center, zoom: event.zoom));
    });

    on<MapInitialized>((event, emit) {
      emit(state.copyWith(isReady: true));
    });
  }
}
