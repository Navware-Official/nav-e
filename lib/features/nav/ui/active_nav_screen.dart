import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:nav_e/features/nav/bloc/nav_bloc.dart';
import 'package:nav_e/features/nav/bloc/nav_event.dart';
import 'package:nav_e/features/nav/bloc/nav_state.dart';
import 'package:nav_e/features/nav/models/nav_models.dart';
import 'package:nav_e/features/map_layers/presentation/map_widget.dart';
import 'package:nav_e/features/map_layers/models/polyline_model.dart';
import 'package:nav_e/features/map_layers/models/marker_model.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/map_controls_fab.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/recenter_fab.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/rotate_north_fab.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/theme/palette.dart';
import 'package:nav_e/core/theme/typography.dart';
import 'package:nav_e/features/hud_widgets/presentation/hud_widget_strip.dart';
import 'package:nav_e/widgets/user_location_marker.dart';
import 'package:nav_e/features/nav/ui/route_finish_screen.dart';
import 'package:nav_e/app/app_router.dart';
import 'package:go_router/go_router.dart';

class ActiveNavScreen extends StatefulWidget {
  final String routeId;
  final List<LatLng> routePoints;
  final double? distanceM;
  final double? durationS;
  final String? destinationLabel;

  /// When set, reuses this Rust session instead of creating a new one (e.g. resume from home).
  final String? sessionId;

  const ActiveNavScreen({
    super.key,
    required this.routeId,
    required this.routePoints,
    this.distanceM,
    this.durationS,
    this.destinationLabel,
    this.sessionId,
  });

  @override
  State<ActiveNavScreen> createState() => _ActiveNavScreenState();
}

class _ActiveNavScreenState extends State<ActiveNavScreen>
    with SingleTickerProviderStateMixin {
  late final NavBloc _navBloc;
  late final AnimationController _puckController;
  LatLng? _puckFrom;
  LatLng? _puckTo;
  LatLng? _puckCurrent;

  // Cached ancestor lookup. Captured in didChangeDependencies so listeners
  // can use it without going through context.read — context lookups crash
  // when this screen is being torn down (Element can be in the inactive
  // lifecycle state where mounted == true but ancestor lookup is unsafe).
  MapBloc? _mapBlocRef;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mapBlocRef = context.read<MapBloc>();
  }

  void _onPuckTick() {
    if (_puckFrom == null || _puckTo == null) return;
    final t = Curves.easeInOut.transform(_puckController.value);
    setState(() {
      _puckCurrent = LatLng(
        _puckFrom!.latitude + (_puckTo!.latitude - _puckFrom!.latitude) * t,
        _puckFrom!.longitude + (_puckTo!.longitude - _puckFrom!.longitude) * t,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _navBloc = NavBloc();
    _puckController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(_onPuckTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _navBloc.add(
        NavStart(
          widget.routeId,
          widget.routePoints,
          distanceM: widget.distanceM,
          durationS: widget.durationS,
          destinationLabel: widget.destinationLabel,
          sessionId: widget.sessionId,
        ),
      );
      _navBloc.add(SetFollowMode(true));

      final mapBloc = context.read<MapBloc>();
      final locState = context.read<LocationBloc>().state;
      final targetCenter = locState.position ?? mapBloc.state.center;
      final targetZoom = mapBloc.state.zoom < 17.0 ? 17.0 : mapBloc.state.zoom;

      // Use GPS heading if available, otherwise derive from the first route
      // segment so the camera already faces the direction of travel.
      final initialBearing =
          locState.heading ??
          (widget.routePoints.length >= 2
              ? _bearingBetween(widget.routePoints[0], widget.routePoints[1])
              : null);

      // Draw the route polyline first (this disables followUser in MapBloc).
      try {
        mapBloc.add(
          ReplacePolylines(
            widget.routePoints.isNotEmpty
                ? [
                    PolylineModel(
                      id: widget.routeId,
                      points: widget.routePoints,
                      colorArgb:
                          mapBloc.state.defaultPolylineColorArgb ?? 0xFF375AF9,
                      strokeWidth: mapBloc.state.defaultPolylineWidth ?? 4.0,
                    ),
                  ]
                : const [],
            fit: false,
          ),
        );
      } catch (_) {}

      // Position the camera tilted toward the direction of travel.
      mapBloc.add(
        MapMoved(
          targetCenter,
          targetZoom,
          force: true,
          tilt: 45.0,
          bearing: initialBearing,
        ),
      );

      // Re-enable follow AFTER ReplacePolylines (which would have cleared it).
      mapBloc.add(ToggleFollowUser(true));
    });
  }

  @override
  void dispose() {
    _puckController.dispose();
    final mapBloc = _mapBlocRef;
    if (mapBloc != null && !mapBloc.isClosed) {
      final mapState = mapBloc.state;
      mapBloc.add(
        MapMoved(
          mapState.center,
          mapState.zoom,
          force: true,
          tilt: 0.0,
          bearing: 0.0,
        ),
      );
      mapBloc.add(ToggleFollowUser(false));
    }
    _navBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _navBloc,
      child: MultiBlocListener(
        listeners: [
          // Reroute: update map polyline whenever progressPolyline changes.
          BlocListener<NavBloc, NavState>(
            listenWhen: (prev, curr) =>
                prev.progressPolyline != curr.progressPolyline &&
                !curr.isRerouting,
            listener: (context, state) {
              if (!mounted || state.progressPolyline.isEmpty) return;
              final mapBloc = _mapBlocRef;
              if (mapBloc == null || mapBloc.isClosed) return;
              mapBloc.add(
                ReplacePolylines([
                  PolylineModel(
                    id: state.routeId ?? 'rerouted',
                    points: state.progressPolyline,
                    colorArgb:
                        mapBloc.state.defaultPolylineColorArgb ?? 0xFF375AF9,
                    strokeWidth: mapBloc.state.defaultPolylineWidth ?? 4.0,
                  ),
                ], fit: false),
              );
            },
          ),
          BlocListener<NavBloc, NavState>(
            listenWhen: (prev, curr) =>
                (prev.active && !curr.active) ||
                (curr.active && prev.progressPolyline != curr.progressPolyline),
            listener: (context, state) {
              if (!state.active) {
                if (state.completedWithSummary &&
                    state.startedAt != null &&
                    state.distanceM != null &&
                    state.durationS != null) {
                  final payload = RouteFinishPayload(
                    distanceM: state.distanceM!,
                    durationS: state.durationS!.toDouble(),
                    startedAt: state.startedAt!,
                    completedAt: DateTime.now(),
                    completed: true,
                    destinationLabel: state.destinationLabel,
                    routeId: state.routeId,
                    routePoints: widget.routePoints,
                  );
                  final navigator = Navigator.of(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    navigator.pop();
                    final rootContext = rootNavigatorKey.currentContext;
                    if (rootContext != null) {
                      GoRouter.of(
                        rootContext,
                      ).pushNamed('routeFinish', extra: payload);
                    }
                  });
                } else {
                  Navigator.of(context).maybePop();
                }
                return;
              }

              if (!mounted) return;
              final mapBloc = _mapBlocRef;
              if (mapBloc == null ||
                  mapBloc.isClosed ||
                  state.progressPolyline.isEmpty) {
                return;
              }
              mapBloc.add(
                ReplacePolylines([
                  PolylineModel(
                    id: '${widget.routeId}-prog',
                    points: state.progressPolyline,
                    colorArgb: AppPalette.blueRibbonDark02.toARGB32(),
                    strokeWidth: 6.0,
                  ),
                ], fit: false),
              );
            },
          ),
          BlocListener<LocationBloc, LocationState>(
            listenWhen: (prev, curr) =>
                curr.position != null && prev.position != curr.position,
            listener: (context, locState) {
              if (!mounted) return;
              // Use the locally-owned _navBloc instead of context.read so we
              // don't crash when LocationBloc fires while this screen is being
              // torn down (Element can be inactive even when mounted).
              _navBloc.add(PositionUpdate(locState.position!));
            },
          ),
          BlocListener<LocationBloc, LocationState>(
            listenWhen: (prev, curr) =>
                prev.heading != curr.heading || prev.position != curr.position,
            listener: (context, locState) {
              if (!mounted) return;
              // Update puck interpolation target.
              final rawPos =
                  _navBloc.state.snappedPosition ?? locState.position;
              if (rawPos != null) {
                if (_puckCurrent == null) {
                  setState(() => _puckCurrent = rawPos);
                }
                _puckFrom = _puckCurrent;
                _puckTo = rawPos;
                _puckController
                  ..stop()
                  ..value = 0.0
                  ..forward();
              }
              final mapBloc = _mapBlocRef;
              if (mapBloc == null) return;
              final mapState = mapBloc.state;
              if (!mapState.followUser) return;
              final heading = locState.heading ?? mapState.bearing;
              final rawCenter =
                  _navBloc.state.snappedPosition ??
                  locState.position ??
                  mapState.center;
              // Offset the camera 150 m ahead so the user appears in the
              // lower third of the screen (Google Maps–style look-ahead).
              final center = _lookaheadPosition(rawCenter, heading, 150.0);
              mapBloc.add(
                MapMoved(
                  center,
                  mapState.zoom,
                  force: true,
                  tilt: 45.0,
                  bearing: heading,
                ),
              );
            },
          ),
        ],
        child: BlocBuilder<LocationBloc, LocationState>(
          builder: (context, locState) {
            final markerPos = _puckCurrent;
            final markers = <MarkerModel>[
              if (markerPos != null)
                MarkerModel(
                  id: 'user_location',
                  position: markerPos,
                  icon: UserLocationMarker(heading: locState.heading),
                ),
            ];

            return Scaffold(
              extendBodyBehindAppBar: true,
              body: Stack(
                children: [
                  Positioned.fill(child: MapWidget(markers: markers)),
                  const Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _TopTurnBar(),
                  ),
                  const RecenterFAB(),
                  const RotateNorthFAB(),
                  const MapControlsFAB(),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(top: false, child: HudWidgetStrip()),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopTurnBar extends StatelessWidget {
  const _TopTurnBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavBloc, NavState>(
      builder: (context, state) {
        if (!state.active) return const SizedBox.shrink();

        final nextCue = state.nextCue ?? _cueFromFeed(state, 0);
        final followingCue = _cueFromFeed(state, 1);

        final instruction = nextCue?.instruction ?? 'Proceed';
        final distanceText = nextCue != null
            ? (nextCue.distanceToCueText.isNotEmpty
                  ? nextCue.distanceToCueText
                  : nextCue.distanceToCueM > 0
                  ? '${nextCue.distanceToCueM.toStringAsFixed(0)} m'
                  : null)
            : null;
        final followingInstruction = followingCue?.instruction;

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final appColors = theme.extension<AppColors>()!;
        final textTheme = theme.textTheme;

        // Extract speed limit from constraint alerts if present.
        final speedLimitAlert = state.constraintAlerts
            .where((a) => a.startsWith('speed_limit:'))
            .firstOrNull;
        final speedLimitKmh = speedLimitAlert != null
            ? int.tryParse(speedLimitAlert.split(':').last)
            : null;

        // Split the distance text into number + unit so we can render the
        // number in the Bitcount display face.
        final (distNum, distUnit) = _splitDistance(distanceText);

        final turnCard = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            // Translucent dark panel sits above the map; brand-blue hairline
            // identifies it as the active turn surface.
            color: const Color(0xEB000000),
            border: Border.all(color: appColors.hiVis, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: appColors.hiVis.withValues(alpha: 0.18),
                  border: Border.all(color: appColors.hiVis, width: 1),
                ),
                child: Icon(
                  _iconForCue(nextCue?.maneuver),
                  color: appColors.hiVis,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14), // off-grid (matches design)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (distNum != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            distNum,
                            style: AppTypography.readout.copyWith(
                              fontSize: 36,
                              height: 1.0,
                              color: appColors.hiVis,
                            ),
                          ),
                          if (distUnit != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              distUnit,
                              style: AppTypography.labelMicro.copyWith(
                                color: appColors.fgMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    Text(
                      instruction,
                      style: textTheme.bodyMedium?.copyWith(
                        color: appColors.fgPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (followingInstruction != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.subdirectory_arrow_left,
                            color: appColors.fgMuted,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'THEN · ${followingInstruction.toUpperCase()}',
                              style: AppTypography.labelMicro.copyWith(
                                color: appColors.fgSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isRerouting)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xEB000000),
                    border: Border.all(color: appColors.borderStrong, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RECALCULATING',
                        style: AppTypography.label.copyWith(
                          fontSize: 10,
                          color: appColors.fgSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else if (state.isOffRoute)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: appColors.danger.withValues(alpha: 0.18),
                    border: Border.all(color: appColors.danger, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: appColors.danger,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'OFF ROUTE',
                        style: AppTypography.label.copyWith(
                          fontSize: 10,
                          color: appColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  turnCard,
                  if (speedLimitKmh != null)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppPalette.brandWhite,
                          shape: BoxShape.circle,
                          border: Border.all(color: appColors.danger, width: 3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$speedLimitKmh',
                          style: AppTypography.readout.copyWith(
                            fontSize: 14,
                            height: 1.0,
                            color: AppPalette.brandBlack,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static (String?, String?) _splitDistance(String? text) {
    if (text == null || text.isEmpty) return (null, null);
    final m = RegExp(r'^([\d.,]+)\s*(\D+)$').firstMatch(text);
    if (m == null) return (text, null);
    return (m.group(1), m.group(2)?.trim().toUpperCase());
  }

  NavCue? _cueFromFeed(NavState state, int index) {
    if (state.turnFeed.length <= index) return null;
    return state.turnFeed[index];
  }
}

/// Returns a point [distanceM] metres ahead of [from] along [bearingDeg].
/// Used to offset the camera so the user appears in the lower third of the
/// screen (Google Maps–style look-ahead).
LatLng _lookaheadPosition(LatLng from, double bearingDeg, double distanceM) {
  const earthR = 6371000.0;
  final angDist = distanceM / earthR;
  final bearing = bearingDeg * math.pi / 180;
  final lat1 = from.latitude * math.pi / 180;
  final lon1 = from.longitude * math.pi / 180;
  final lat2 = math.asin(
    math.sin(lat1) * math.cos(angDist) +
        math.cos(lat1) * math.sin(angDist) * math.cos(bearing),
  );
  final lon2 =
      lon1 +
      math.atan2(
        math.sin(bearing) * math.sin(angDist) * math.cos(lat1),
        math.cos(angDist) - math.sin(lat1) * math.sin(lat2),
      );
  return LatLng(lat2 * 180 / math.pi, lon2 * 180 / math.pi);
}

/// Returns the compass bearing (0–360°) from [a] to [b].
double _bearingBetween(LatLng a, LatLng b) {
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final dLon = (b.longitude - a.longitude) * math.pi / 180;
  final y = math.sin(dLon) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

IconData _iconForCue(String? maneuver) {
  final m = maneuver ?? '';
  if (m.contains('uturn')) return Icons.u_turn_left;
  if (m.contains('sharp_left')) return Icons.turn_sharp_left;
  if (m.contains('sharp_right')) return Icons.turn_sharp_right;
  if (m.contains('left')) return Icons.turn_left;
  if (m.contains('right')) return Icons.turn_right;
  return Icons.straight;
}
