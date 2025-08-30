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
