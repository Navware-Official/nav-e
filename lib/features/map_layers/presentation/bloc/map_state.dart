import 'package:latlong2/latlong.dart';

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
