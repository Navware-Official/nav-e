import 'package:latlong2/latlong.dart';

class NavCue {
  final String id;
  final String instruction;
  final double distanceToCueM;
  final String distanceToCueText;
  final LatLng location;
  final String maneuver;

  NavCue({
    required this.id,
    required this.instruction,
    required this.distanceToCueM,
    required this.distanceToCueText,
    required this.location,
    required this.maneuver,
  });
}
