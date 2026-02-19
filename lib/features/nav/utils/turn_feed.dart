import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/features/nav/models/nav_models.dart';

const _turnThresholdDeg = 25.0;
const _minTurnSpacingM = 30.0;

/// Builds turn-by-turn cues from a route polyline.
///
/// [points] is the route geometry (start to end).
/// [segmentRoadNames] is optional: names of the road for each segment, so
/// `segmentRoadNames[i]` is the name of the road from `points[i]` to
/// `points[i + 1]`. Length should be `points.length - 1`. When provided,
/// each cue's instruction includes " onto &lt;name&gt;" when the name is
/// non-empty (e.g. "Turn left onto Main St"). When the routing API returns
/// step/road names (e.g. from OSRM steps), pass them here.
List<NavCue> buildTurnFeed(
  List<LatLng> points, {
  List<String?>? segmentRoadNames,
}) {
  debugPrint('[TurnFeed] buildTurnFeed points=${points.length}');
  if (points.length < 3) return const [];

  final distance = const Distance();
  final cues = <NavCue>[];
  double cumulative = 0.0;
  double sinceLastTurn = 0.0;
  final useRoadNames = segmentRoadNames != null &&
      segmentRoadNames.length >= points.length - 1;

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

    final cumulativeText = cumulative >= 1000
        ? '${(cumulative / 1000).toStringAsFixed(1)} km'
        : '${cumulative.toStringAsFixed(0)} m';

    final maneuver = _turnType(delta);
    final String? streetName = useRoadNames && i < segmentRoadNames.length
        ? segmentRoadNames[i]
        : null;
    final name = streetName != null && streetName.trim().isNotEmpty
        ? streetName.trim()
        : null;
    cues.add(
      NavCue(
        id: 'turn_$i',
        instruction: _instructionFor(maneuver, ontoStreetName: name),
        distanceToCueM: cumulative,
        distanceToCueText: cumulativeText,
        location: curr,
        maneuver: maneuver,
        streetName: name,
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

String _instructionFor(String maneuver, {String? ontoStreetName}) {
  final base = switch (maneuver) {
    'uturn_left' => 'Make a U-turn left',
    'uturn_right' => 'Make a U-turn right',
    'sharp_left' => 'Turn sharp left',
    'sharp_right' => 'Turn sharp right',
    'left' => 'Turn left',
    'right' => 'Turn right',
    'slight_left' => 'Slight left',
    'slight_right' => 'Slight right',
    _ => 'Continue',
  };
  if (ontoStreetName != null && ontoStreetName.isNotEmpty) {
    return '$base onto $ontoStreetName';
  }
  return base;
}

double _degToRad(double deg) => deg * math.pi / 180.0;

double _radToDeg(double rad) => rad * 180.0 / math.pi;
