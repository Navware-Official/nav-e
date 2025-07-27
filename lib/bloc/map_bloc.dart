import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

abstract class MapEvent {}

class MapMoved extends MapEvent {
  final LatLng center;
  final double zoom;
  MapMoved(this.center, this.zoom);
}

class MapInitialized extends MapEvent {}

class ToggleFollowUser extends MapEvent {
  final bool follow;
  ToggleFollowUser(this.follow);
}

class MapState {
  final LatLng center;
  final double zoom;
  final bool isReady;
  final bool followUser;

  MapState({
    required this.center,
    required this.zoom,
    required this.isReady,
    this.followUser = true,
  });

  MapState copyWith({
    LatLng? center,
    double? zoom,
    bool? isReady,
    bool? followUser,
  }) {
    return MapState(
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      isReady: isReady ?? this.isReady,
      followUser: followUser ?? this.followUser,
    );
  }
}

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc()
      : super(MapState(
          center: LatLng(52.3791, 4.9),
          zoom: 13.0,
          isReady: false,
        )) {
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
