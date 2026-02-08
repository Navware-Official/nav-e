import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/features/nav/models/nav_models.dart';

const _turnThresholdDeg = 25.0;
const _minTurnSpacingM = 30.0;

List<NavCue> buildTurnFeed(List<LatLng> points) {
  debugPrint('[TurnFeed] buildTurnFeed points=${points.length}');
  if (points.length < 3) return const [];

  final distance = const Distance();
  final cues = <NavCue>[];
  double cumulative = 0.0;
  double sinceLastTurn = 0.0;

  for (var i = 1; i < points.length - 1; i++) {
    final prev = points[i - 1];
    final curr = points[i];
    final next = points[i + 1];

    final seg = distance(prev, curr);
    cumulative += seg;
    sinceLastTurn += seg;

    final b1 = _bearing(prev, curr);
    final b2 = _bearing(curr, next);
    final delta = _deltaAngle(b1, b2);

    debugPrint(
      '[TurnFeed] i=$i seg=${seg.toStringAsFixed(1)}m '
      'b1=${b1.toStringAsFixed(1)} b2=${b2.toStringAsFixed(1)} '
      'delta=${delta.toStringAsFixed(1)} sinceLast=${sinceLastTurn.toStringAsFixed(1)}',
    );

    if (delta.abs() < _turnThresholdDeg || sinceLastTurn < _minTurnSpacingM) {
      continue;
    }

    final maneuver = _turnType(delta);
    debugPrint(
      '[TurnFeed] turn $maneuver at ${curr.latitude},${curr.longitude} '
      'dist=${cumulative.toStringAsFixed(1)}m',
    );
    cues.add(
      NavCue(
        id: 'turn_$i',
        instruction: _instructionFor(maneuver),
        distanceToCueM: cumulative,
        location: curr,
        maneuver: maneuver,
      ),
    );
    sinceLastTurn = 0.0;
  }

  return cues;
}

double _bearing(LatLng a, LatLng b) {
  final lat1 = _degToRad(a.latitude);
  final lat2 = _degToRad(b.latitude);
  final dLon = _degToRad(b.longitude - a.longitude);

  final y = math.sin(dLon) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  final brng = math.atan2(y, x);
  return (_radToDeg(brng) + 360) % 360;
}

double _deltaAngle(double from, double to) {
  final diff = (to - from + 540) % 360 - 180;
  return diff;
}

String _turnType(double delta) {
  final abs = delta.abs();
  final dir = delta > 0 ? 'right' : 'left';

  if (abs > 160) return 'uturn_$dir';
  if (abs > 100) return 'sharp_$dir';
  if (abs > 45) return dir;
  return 'slight_$dir';
}

String _instructionFor(String maneuver) {
  switch (maneuver) {
    case 'uturn_left':
      return 'Make a U-turn left';
    case 'uturn_right':
      return 'Make a U-turn right';
    case 'sharp_left':
      return 'Turn sharp left';
    case 'sharp_right':
      return 'Turn sharp right';
    case 'left':
      return 'Turn left';
    case 'right':
      return 'Turn right';
    case 'slight_left':
      return 'Slight left';
    case 'slight_right':
      return 'Slight right';
    default:
      return 'Continue';
  }
}

double _degToRad(double deg) => deg * math.pi / 180.0;

double _radToDeg(double rad) => rad * 180.0 / math.pi;
