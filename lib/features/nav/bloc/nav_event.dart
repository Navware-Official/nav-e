import 'package:latlong2/latlong.dart';

import '../models/nav_models.dart';

abstract class NavEvent {}

class NavStart extends NavEvent {
  final String routeId;
  final List<LatLng> routePoints;
  final Map<String, dynamic>? options;

  NavStart(this.routeId, this.routePoints, {this.options});
}

class NavStop extends NavEvent {}

class PositionUpdate extends NavEvent {
  final LatLng position;
  final double? speed;
  final double? bearing;

  PositionUpdate(this.position, {this.speed, this.bearing});
}

class CueFromNative extends NavEvent {
  final NavCue cue;

  CueFromNative(this.cue);
}

class SetFollowMode extends NavEvent {
  final bool follow;

  SetFollowMode(this.follow);
}
