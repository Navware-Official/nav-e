import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'nav_event.dart';
import 'nav_state.dart';
import 'off_route_detector.dart';
import 'nav_session_manager.dart';
import 'package:nav_e/bridge/lib.dart' as api;
import 'package:nav_e/core/nav/nav_settings_service.dart';
import 'package:nav_e/core/notifications/nav_notification_service.dart';

class NavBloc extends Bloc<NavEvent, NavState> {
  final _detector = OffRouteDetector(
    thresholdM: NavSettingsService.defaultOffRouteThresholdM,
  );
  final _session = NavSessionManager();

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
    _detector.threshold = await NavSettingsService.getOffRouteThreshold();
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
    final sid =
        event.sessionId ?? await _session.startSession(event.routePoints);

    if (sid != null && state.active) {
      emit(state.copyWith(sessionId: sid));
      final steps = await _session.loadTurnFeed(sid, state.lastPosition);
      if (steps.isNotEmpty && state.active) {
        add(SetTurnFeed(steps));
      }
    }
  }

  Future<void> _onStop(NavStop event, Emitter<NavState> emit) async {
    final sid = state.sessionId;
    if (sid != null) await _session.stop(sid);

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
      final isOffRoute = _detector.isOffRoute(ns.distanceFromRouteM);
      final snappedPosition = LatLng(ns.snappedLat, ns.snappedLon);
      final loc = state.lastPosition ?? const LatLng(0, 0);

      // Build next cue from typed DTO fields (type inferred — avoids importing ffi_models.dart).
      final nextInst = ns.nextInstruction;
      final currentInst = ns.currentInstruction;
      final nextCue = nextInst != null
          ? NavSessionManager.buildCue(
              id: 'next_${nextInst.kind}_${nextInst.distanceToNextM.toInt()}',
              kind: nextInst.kind,
              streetName: nextInst.streetName,
              distanceToNextM: nextInst.distanceToNextM,
              location: loc,
            )
          : NavSessionManager.buildCue(
              id: 'curr_${currentInst.kind}',
              kind: currentInst.kind,
              streetName: currentInst.streetName,
              distanceToNextM: 0.0,
              location: loc,
            );

      if (_detector.update(ns.distanceFromRouteM)) {
        add(const NavReroute());
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
    if (sid != null) await _session.pause(sid);
    emit(state.copyWith(isPaused: true));
  }

  Future<void> _onResume(NavResume _, Emitter<NavState> emit) async {
    final sid = state.sessionId;
    if (sid != null) await _session.resume(sid);
    emit(state.copyWith(isPaused: false));
  }

  Future<void> _onReroute(NavReroute _, Emitter<NavState> emit) async {
    final origin = state.lastPosition;
    final dest = state.progressPolyline.isNotEmpty
        ? state.progressPolyline.last
        : null;
    if (origin == null || dest == null) return;

    _detector.markRerouting();
    emit(state.copyWith(isRerouting: true));

    try {
      final result = await _session.reroute(origin: origin, destination: dest);
      NavNotificationService.instance.showRerouted();
      emit(
        state.copyWith(
          sessionId: result.sessionId,
          progressPolyline: result.points,
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
}
