import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../models/nav_models.dart';

class NavState extends Equatable {
  final bool active;
  final String? routeId;

  /// Rust navigation session ID, used for `updateNavigationPosition` FFI calls.
  final String? sessionId;
  final double? remainingDistanceM;
  final int? remainingSeconds;
  final NavCue? nextCue;
  final List<LatLng> progressPolyline;
  final List<NavCue> turnFeed;
  final double? speed;
  final LatLng? lastPosition;
  final bool following;
  final bool lightweightMode;
  final DateTime? startedAt;
  final double? distanceM;
  final int? durationS;
  final String? destinationLabel;
  final bool completedWithSummary;
  final bool isOffRoute;
  final bool isPaused;
  final bool isRerouting;
  final List<String> constraintAlerts;

  /// GPS position snapped onto the route polyline by the nav engine.
  final LatLng? snappedPosition;

  const NavState({
    this.active = false,
    this.routeId,
    this.sessionId,
    this.remainingDistanceM,
    this.remainingSeconds,
    this.nextCue,
    this.progressPolyline = const [],
    this.turnFeed = const [],
    this.speed,
    this.lastPosition,
    this.following = false,
    this.lightweightMode = false,
    this.startedAt,
    this.distanceM,
    this.durationS,
    this.destinationLabel,
    this.completedWithSummary = false,
    this.isOffRoute = false,
    this.isPaused = false,
    this.isRerouting = false,
    this.constraintAlerts = const [],
    this.snappedPosition,
  });

  NavState copyWith({
    bool? active,
    String? routeId,
    String? sessionId,
    double? remainingDistanceM,
    int? remainingSeconds,
    NavCue? nextCue,
    List<LatLng>? progressPolyline,
    List<NavCue>? turnFeed,
    double? speed,
    LatLng? lastPosition,
    bool? following,
    bool? lightweightMode,
    DateTime? startedAt,
    double? distanceM,
    int? durationS,
    String? destinationLabel,
    bool? completedWithSummary,
    bool? isOffRoute,
    bool? isPaused,
    bool? isRerouting,
    List<String>? constraintAlerts,
    LatLng? snappedPosition,
  }) {
    return NavState(
      active: active ?? this.active,
      routeId: routeId ?? this.routeId,
      sessionId: sessionId ?? this.sessionId,
      remainingDistanceM: remainingDistanceM ?? this.remainingDistanceM,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      nextCue: nextCue ?? this.nextCue,
      progressPolyline: progressPolyline ?? this.progressPolyline,
      turnFeed: turnFeed ?? this.turnFeed,
      speed: speed ?? this.speed,
      lastPosition: lastPosition ?? this.lastPosition,
      following: following ?? this.following,
      lightweightMode: lightweightMode ?? this.lightweightMode,
      startedAt: startedAt ?? this.startedAt,
      distanceM: distanceM ?? this.distanceM,
      durationS: durationS ?? this.durationS,
      destinationLabel: destinationLabel ?? this.destinationLabel,
      completedWithSummary: completedWithSummary ?? this.completedWithSummary,
      isOffRoute: isOffRoute ?? this.isOffRoute,
      isPaused: isPaused ?? this.isPaused,
      isRerouting: isRerouting ?? this.isRerouting,
      constraintAlerts: constraintAlerts ?? this.constraintAlerts,
      snappedPosition: snappedPosition ?? this.snappedPosition,
    );
  }

  @override
  List<Object?> get props => [
    active,
    routeId,
    sessionId,
    remainingDistanceM,
    remainingSeconds,
    nextCue,
    progressPolyline,
    turnFeed,
    speed,
    lastPosition,
    following,
    lightweightMode,
    startedAt,
    distanceM,
    durationS,
    destinationLabel,
    completedWithSummary,
    isOffRoute,
    isPaused,
    isRerouting,
    constraintAlerts,
    snappedPosition,
  ];
}
