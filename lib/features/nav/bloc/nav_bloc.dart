import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'nav_event.dart';
import 'nav_state.dart';
import '../models/nav_models.dart';
import 'package:nav_e/bridge/lib.dart' as api;
import 'package:nav_e/core/nav/nav_settings_service.dart';
import 'package:nav_e/core/notifications/nav_notification_service.dart';

class NavBloc extends Bloc<NavEvent, NavState> {
  int _offRouteCount = 0;
  bool _offRouteNotified = false;
  DateTime? _lastRerouteAt;
  double _offRouteThresholdM = NavSettingsService.defaultOffRouteThresholdM;

  NavBloc() : super(const NavState()) {
    on<NavStart>(_onStart);
    on<NavStop>(_onStop);
    on<PositionUpdate>(_onPositionUpdate);
    on<CueFromNative>(_onCue);
    on<SetFollowMode>(_onSetFollow);
    on<SetTurnFeed>(_onSetTurnFeed);
    on<NavPause>(_onPause);
    on<NavResume>(_onResume);
    on<NavReroute>(_onReroute);
  }

  Future<void> _onStart(NavStart event, Emitter<NavState> emit) async {
    _offRouteThresholdM = await NavSettingsService.getOffRouteThreshold();
    final dist = _computeTotalDistance(event.routePoints);
    emit(
      state.copyWith(
        active: true,
        routeId: event.routeId,
        remainingDistanceM: dist,
        progressPolyline: event.routePoints,
        startedAt: DateTime.now(),
        distanceM: event.distanceM,
        durationS: event.durationS?.toInt(),
        destinationLabel: event.destinationLabel,
      ),
    );

    // If a session ID was provided (e.g. restore on cold start), skip creating a new session.
    String? sid = event.sessionId;

    if (sid == null && event.routePoints.length >= 2) {
      try {
        final start = event.routePoints.first;
        final end = event.routePoints.last;
        final session = await api.startNavigationSession(
          waypoints: [
            (start.latitude, start.longitude),
            (end.latitude, end.longitude),
          ],
          currentPosition: (start.latitude, start.longitude),
        );
        sid = session.id;
      } catch (_) {
        // Non-fatal — nav continues client-side without Rust session state.
      }
    }

    if (sid != null && state.active) {
      emit(state.copyWith(sessionId: sid));

      // Populate turn feed from route steps.
      try {
        final steps = (await api.getRouteSteps(sessionId: sid))
            .asMap()
            .entries
            .map((entry) {
          final s = entry.value;
          return NavCue(
            id: 'step_${entry.key}',
            instruction: _instructionFor(s.kind, s.streetName),
            distanceToCueM: s.distanceToNextM,
            distanceToCueText: _formatDistanceText(s.distanceToNextM),
            location: state.lastPosition ?? const LatLng(0, 0),
            maneuver: s.kind,
            streetName: s.streetName,
          );
        }).toList();
        if (state.active) {
          add(SetTurnFeed(steps));
        }
      } catch (_) {
        // Non-fatal — turn feed remains empty.
      }
    }
  }

  Future<void> _onStop(NavStop event, Emitter<NavState> emit) async {
    final sid = state.sessionId;
    if (sid != null) {
      try {
        await api.stopNavigation(sessionId: sid);
      } catch (_) {}
    }

    if (event.completed && state.startedAt != null) {
      final now = DateTime.now();
      final durationS = now.difference(state.startedAt!).inSeconds;
      try {
        api.saveTrip(
          distanceM: state.distanceM ?? 0,
          durationSeconds: durationS,
          startedAt: state.startedAt!.millisecondsSinceEpoch ~/ 1000,
          completedAt: now.millisecondsSinceEpoch ~/ 1000,
          status: 'Completed',
          destinationLabel: state.destinationLabel,
          routeId: state.routeId,
          polylineEncoded: null,
        );
      } catch (_) {}
      emit(state.copyWith(active: false, completedWithSummary: true));
    } else {
      emit(const NavState());
    }
  }

  void _onPositionUpdate(PositionUpdate event, Emitter<NavState> emit) async {
    if (!state.active) return;

    emit(state.copyWith(lastPosition: event.position, speed: event.speed));

    if (state.isPaused) return;

    final sid = state.sessionId;
    if (sid == null || !state.active) return;

    try {
      final ns = await api.updateNavigationPosition(
        sessionId: sid,
        latitude: event.position.latitude,
        longitude: event.position.longitude,
      );
      final isOffRoute = ns.distanceFromRouteM > _offRouteThresholdM;
      final snappedPosition = LatLng(ns.snappedLat, ns.snappedLon);

      final nextInst = ns.nextInstruction;
      final currentInst = ns.currentInstruction;
      NavCue? nextCue;
      if (nextInst != null) {
        nextCue = NavCue(
          id: 'next_${nextInst.kind}_${nextInst.distanceToNextM.toInt()}',
          instruction: _instructionFor(nextInst.kind, nextInst.streetName),
          distanceToCueM: nextInst.distanceToNextM,
          distanceToCueText: _formatDistanceText(nextInst.distanceToNextM),
          location: state.lastPosition ?? const LatLng(0, 0),
          maneuver: nextInst.kind,
          streetName: nextInst.streetName,
        );
      } else {
        nextCue = NavCue(
          id: 'curr_${currentInst.kind}',
          instruction:
              _instructionFor(currentInst.kind, currentInst.streetName),
          distanceToCueM: 0.0,
          distanceToCueText: '',
          location: state.lastPosition ?? const LatLng(0, 0),
          maneuver: currentInst.kind,
          streetName: currentInst.streetName,
        );
      }

      // Off-route debounce → notification + auto-reroute
      if (isOffRoute) {
        _offRouteCount++;
        if (!_offRouteNotified) {
          _offRouteNotified = true;
          NavNotificationService.instance.showOffRoute();
        }
        final lastReroute = _lastRerouteAt;
        final cooldownOk =
            lastReroute == null ||
            DateTime.now().difference(lastReroute).inSeconds > 30;
        if (_offRouteCount >= 3 && cooldownOk) {
          add(const NavReroute());
          _offRouteCount = 0;
        }
      } else {
        _offRouteCount = 0;
        _offRouteNotified = false;
      }

      emit(
        state.copyWith(
          remainingDistanceM: ns.distanceRemainingM,
          remainingSeconds: ns.etaSeconds.toInt(),
          nextCue: nextCue,
          isOffRoute: isOffRoute,
          constraintAlerts: ns.constraintAlerts,
          snappedPosition: snappedPosition,
        ),
      );
    } catch (_) {
      // FFI not ready or session ended — continue with position-only state
    }
  }

  Future<void> _onPause(NavPause _, Emitter<NavState> emit) async {
    final sid = state.sessionId;
    if (sid != null) {
      try {
        await api.pauseNavigation(sessionId: sid);
      } catch (_) {}
    }
    emit(state.copyWith(isPaused: true));
  }

  Future<void> _onResume(NavResume _, Emitter<NavState> emit) async {
    final sid = state.sessionId;
    if (sid != null) {
      try {
        await api.resumeNavigation(sessionId: sid);
      } catch (_) {}
    }
    emit(state.copyWith(isPaused: false));
  }

  Future<void> _onReroute(NavReroute _, Emitter<NavState> emit) async {
    final origin = state.lastPosition;
    final dest = state.progressPolyline.isNotEmpty
        ? state.progressPolyline.last
        : null;
    if (origin == null || dest == null) return;

    _lastRerouteAt = DateTime.now();
    emit(state.copyWith(isRerouting: true));

    try {
      final route = await api.calculateRoute(
        waypoints: [
          (origin.latitude, origin.longitude),
          (dest.latitude, dest.longitude),
        ],
      );
      final rawPoints = (jsonDecode(route.polylineJson) as List)
          .map(
            (p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()),
          )
          .toList();

      final newSession = await api.startNavigationSession(
        waypoints: [
          (origin.latitude, origin.longitude),
          (dest.latitude, dest.longitude),
        ],
        currentPosition: (origin.latitude, origin.longitude),
      );
      final newSid = newSession.id;

      NavNotificationService.instance.showRerouted();
      emit(
        state.copyWith(
          sessionId: newSid,
          progressPolyline: rawPoints,
          isRerouting: false,
          isOffRoute: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isRerouting: false));
    }
  }

  void _onCue(CueFromNative event, Emitter<NavState> emit) {
    emit(state.copyWith(nextCue: event.cue));
  }

  void _onSetFollow(SetFollowMode event, Emitter<NavState> emit) {
    emit(state.copyWith(following: event.follow));
  }

  void _onSetTurnFeed(SetTurnFeed event, Emitter<NavState> emit) {
    emit(state.copyWith(turnFeed: event.feed));
  }

  double _computeTotalDistance(List<LatLng> pts) {
    if (pts.length < 2) return 0.0;
    final d = Distance();
    double acc = 0.0;
    for (var i = 0; i < pts.length - 1; i++) {
      acc += d.as(LengthUnit.Meter, pts[i], pts[i + 1]);
    }
    return acc;
  }

  static String _instructionFor(String kind, String? streetName) {
    final base = switch (kind) {
      'turn_left' => 'Turn left',
      'turn_right' => 'Turn right',
      'slight_left' => 'Slight left',
      'slight_right' => 'Slight right',
      'sharp_left' => 'Turn sharp left',
      'sharp_right' => 'Turn sharp right',
      'depart' => 'Depart',
      'arrive' => 'You have arrived',
      _ => 'Continue',
    };
    if (streetName != null && streetName.isNotEmpty) {
      return '$base onto $streetName';
    }
    return base;
  }

  static String _formatDistanceText(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }
}
