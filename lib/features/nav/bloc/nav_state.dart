import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../models/nav_models.dart';

class NavState extends Equatable {
  final bool active;
  final String? routeId;
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

  const NavState({
    this.active = false,
    this.routeId,
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
  });

  NavState copyWith({
    bool? active,
    String? routeId,
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
  }) {
    return NavState(
      active: active ?? this.active,
      routeId: routeId ?? this.routeId,
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
    );
  }

  @override
  List<Object?> get props => [
    active,
    routeId,
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
  ];
}
