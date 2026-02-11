import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'nav_event.dart';
import 'nav_state.dart';
import 'dart:async';
import 'dart:convert';

// try dynamic call to generated FRB bindings (if present)
import 'package:nav_e/bridge/frb_generated.dart' as gen;
import '../models/nav_models.dart';

class NavBloc extends Bloc<NavEvent, NavState> {
  NavBloc() : super(const NavState()) {
    on<NavStart>(_onStart);
    on<NavStop>(_onStop);
    on<PositionUpdate>(_onPositionUpdate);
    on<CueFromNative>(_onCue);
    on<SetFollowMode>(_onSetFollow);
    on<SetTurnFeed>(_onSetTurnFeed);
  }

  void _onStart(NavStart event, Emitter<NavState> emit) {
    final dist = _computeTotalDistance(event.routePoints);
    final secs = null; // leave ETA empty for now
    emit(
      state.copyWith(
        active: true,
        routeId: event.routeId,
        remainingDistanceM: dist,
        remainingSeconds: secs,
        progressPolyline: event.routePoints,
      ),
    );
    _startCuePolling();
  }

  void _onStop(NavStop event, Emitter<NavState> emit) {
    emit(const NavState());
    _stopCuePolling();
  }

  void _onPositionUpdate(PositionUpdate event, Emitter<NavState> emit) {
    // naive remaining distance: distance from current pos to last point
    emit(state.copyWith(lastPosition: event.position, speed: event.speed));
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

  Timer? _cueTimer;

  void _startCuePolling() {
    // If polling already active, skip
    if (_cueTimer != null) return;
    // Poll every 400ms for new cues (adaptive rate is possible later)
    _cueTimer = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      try {
        // Attempt dynamic call to generated binding: navNextCue()
        final dynClass = gen.RustBridge;
        String? json;
        try {
          final res = await (dynClass as dynamic).navNextCue();
          if (res != null) json = res as String;
        } catch (_) {
          try {
            final inst = (dynClass as dynamic).instance;
            final res = await (inst as dynamic).navNextCue();
            if (res != null) json = res as String;
          } catch (_) {
            // binding not present or errored; stop polling early
            _stopCuePolling();
            return;
          }
        }

        if (json == null || json.isEmpty) return;
        // parse minimal cue structure
        final Map<String, dynamic> obj =
            jsonDecode(json) as Map<String, dynamic>;
        final cue = NavCue(
          id:
              obj['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          instruction: obj['instruction']?.toString() ?? '',
          distanceToCueM: (obj['distance_to_cue_m'] as num?)?.toDouble() ?? 0.0,
          distanceToCueText: obj['distance_to_cue_text']?.toString() ?? '',
          location: LatLng(
            (obj['location']?[0] as num?)?.toDouble() ?? 0.0,
            (obj['location']?[1] as num?)?.toDouble() ?? 0.0,
          ),
          maneuver: obj['maneuver']?.toString() ?? '',
        );
        add(CueFromNative(cue));
      } catch (_) {
        // no-op; continue polling
      }
    });
  }

  void _stopCuePolling() {
    _cueTimer?.cancel();
    _cueTimer = null;
  }
}
