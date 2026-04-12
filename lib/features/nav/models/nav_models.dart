import 'package:latlong2/latlong.dart';

/// Mirrors [native/nav_core `NavigationStateDto`] JSON from FFI (`updateNavigationPosition`).
class NavigationStateDto {
  final int currentStep;
  final DerivedInstructionDto currentInstruction;
  final DerivedInstructionDto? nextInstruction;
  final double distanceToNextM;
  final double distanceRemainingM;
  final int etaSeconds;
  final bool isOffRoute;
  final double distanceFromRouteM;
  final double snappedLat;
  final double snappedLon;
  final List<String> constraintAlerts;

  NavigationStateDto({
    required this.currentStep,
    required this.currentInstruction,
    this.nextInstruction,
    required this.distanceToNextM,
    required this.distanceRemainingM,
    required this.etaSeconds,
    required this.isOffRoute,
    required this.distanceFromRouteM,
    required this.snappedLat,
    required this.snappedLon,
    required this.constraintAlerts,
  });

  factory NavigationStateDto.fromJson(Map<String, dynamic> json) {
    return NavigationStateDto(
      currentStep: (json['current_step'] as num).toInt(),
      currentInstruction: DerivedInstructionDto.fromJson(
        json['current_instruction'] as Map<String, dynamic>,
      ),
      nextInstruction: json['next_instruction'] == null
          ? null
          : DerivedInstructionDto.fromJson(
              json['next_instruction'] as Map<String, dynamic>,
            ),
      distanceToNextM: (json['distance_to_next_m'] as num).toDouble(),
      distanceRemainingM: (json['distance_remaining_m'] as num).toDouble(),
      etaSeconds: (json['eta_seconds'] as num).toInt(),
      isOffRoute: json['is_off_route'] as bool,
      distanceFromRouteM: (json['distance_from_route_m'] as num).toDouble(),
      snappedLat: (json['snapped_lat'] as num).toDouble(),
      snappedLon: (json['snapped_lon'] as num).toDouble(),
      constraintAlerts: (json['constraint_alerts'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}

class DerivedInstructionDto {
  final String kind;
  final double distanceToNextM;
  final String? streetName;

  DerivedInstructionDto({
    required this.kind,
    required this.distanceToNextM,
    this.streetName,
  });

  factory DerivedInstructionDto.fromJson(Map<String, dynamic> json) {
    return DerivedInstructionDto(
      kind: json['kind'] as String,
      distanceToNextM: (json['distance_to_next_m'] as num).toDouble(),
      streetName: json['street_name'] as String?,
    );
  }
}

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
