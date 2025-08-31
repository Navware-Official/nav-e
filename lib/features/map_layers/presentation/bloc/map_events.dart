import 'package:latlong2/latlong.dart';

abstract class MapEvent {}

class MapInitialized extends MapEvent {}

class MapMoved extends MapEvent {
  final LatLng center;
  final double zoom;
  MapMoved(this.center, this.zoom);
}

class ToggleFollowUser extends MapEvent {
  final bool follow;
  ToggleFollowUser(this.follow);
}

class MapSourceChanged extends MapEvent {
  final String sourceId;
  MapSourceChanged(this.sourceId);
}
