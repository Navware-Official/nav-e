import 'package:latlong2/latlong.dart';

import '../models/nav_models.dart';

abstract class NavEvent {
  const NavEvent();
}

class NavStart extends NavEvent {
  final String routeId;
  final List<LatLng> routePoints;
  final Map<String, dynamic>? options;
  final double? distanceM;
  final double? durationS;
  final String? destinationLabel;

  /// Rust navigation session ID. When set, position updates are forwarded to
  /// `api.updateNavigationPosition()` and turn state comes from Rust.
  final String? sessionId;

  NavStart(
    this.routeId,
    this.routePoints, {
    this.options,
    this.distanceM,
    this.durationS,
    this.destinationLabel,
    this.sessionId,
  });
}

class NavStop extends NavEvent {
  final bool completed;

  const NavStop({this.completed = false});
}

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

class SetTurnFeed extends NavEvent {
  final List<NavCue> feed;

  SetTurnFeed(this.feed);
}

class NavPause extends NavEvent {
  const NavPause();
}

class NavResume extends NavEvent {
  const NavResume();
}

class NavReroute extends NavEvent {
  const NavReroute();
}
