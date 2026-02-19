import 'package:latlong2/latlong.dart';

class NavCue {
  final String id;
  final String instruction;
  final double distanceToCueM;
  final String distanceToCueText;
  final LatLng location;
  final String maneuver;

  /// Optional street/road name for the segment after this turn (e.g. "Main St").
  /// When set, the instruction is typically shown as "Turn left onto Main St".
  final String? streetName;

  NavCue({
    required this.id,
    required this.instruction,
    required this.distanceToCueM,
    required this.distanceToCueText,
    required this.location,
    required this.maneuver,
    this.streetName,
  });
}
