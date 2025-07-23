import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// --- Events ---
abstract class LocationEvent {}

class StartLocationTracking extends LocationEvent {}

class StopLocationTracking extends LocationEvent {}

/// --- State ---
class LocationState {
  final LatLng? position;
  final double? heading;
  final bool tracking;

  LocationState({
    this.position,
    this.heading,
    this.tracking = false,
  });

  LocationState copyWith({
    LatLng? position,
    double? heading,
    bool? tracking,
  }) {
    return LocationState(
      position: position ?? this.position,
      heading: heading ?? this.heading,
      tracking: tracking ?? this.tracking,
    );
  }
}

/// --- Bloc ---
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  StreamSubscription<Position>? _subscription;

  LocationBloc() : super(LocationState()) {
    on<StartLocationTracking>(_startTracking);
    on<StopLocationTracking>(_stopTracking);
  }

  Future<void> _startTracking(
    StartLocationTracking event, Emitter<LocationState> emit) async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final granted = await Geolocator.requestPermission();
      if (granted != LocationPermission.always &&
          granted != LocationPermission.whileInUse) {
        return;
      }
    }

    emit(state.copyWith(tracking: true));

    await emit.forEach<Position>(
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      ),
      onData: (position) => state.copyWith(
        position: LatLng(position.latitude, position.longitude),
        heading: position.heading,
      ),
    );
    print('Location tracking started');
  }

  Future<void> _stopTracking(
      StopLocationTracking event, Emitter<LocationState> emit) async {
    await _subscription?.cancel();
    emit(state.copyWith(tracking: false));
    print('Location tracking stopped');
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
