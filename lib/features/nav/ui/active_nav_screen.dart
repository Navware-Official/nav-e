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
import 'package:nav_e/core/theme/palette.dart';
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
    try {
      final mapBloc = context.read<MapBloc>();
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
    } catch (_) {}
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
              if (!context.mounted || state.progressPolyline.isEmpty) return;
              try {
                final mapBloc = context.read<MapBloc>();
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
              } catch (_) {}
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

              if (!context.mounted) return;
              try {
                if (state.progressPolyline.isNotEmpty) {
                  context.read<MapBloc>().add(
                    ReplacePolylines([
                      PolylineModel(
                        id: '${widget.routeId}-prog',
                        points: state.progressPolyline,
                        colorArgb: AppPalette.blueRibbonDark02.toARGB32(),
                        strokeWidth: 6.0,
                      ),
                    ], fit: false),
                  );
                }
              } catch (_) {}
            },
          ),
          BlocListener<LocationBloc, LocationState>(
            listenWhen: (prev, curr) =>
                curr.position != null && prev.position != curr.position,
            listener: (context, locState) {
              context.read<NavBloc>().add(PositionUpdate(locState.position!));
            },
          ),
          BlocListener<LocationBloc, LocationState>(
            listenWhen: (prev, curr) =>
                prev.heading != curr.heading || prev.position != curr.position,
            listener: (context, locState) {
              if (!context.mounted) return;
              // Update puck interpolation target.
              final rawPos =
                  context.read<NavBloc>().state.snappedPosition ??
                  locState.position;
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
              final mapBloc = context.read<MapBloc>();
              final mapState = mapBloc.state;
              if (!mapState.followUser) return;
              final heading = locState.heading ?? mapState.bearing;
              final rawCenter =
                  context.read<NavBloc>().state.snappedPosition ??
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
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _BottomNavBar(),
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

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final onPrimaryFaded = colorScheme.onPrimary.withValues(alpha: 0.75);

        // Extract speed limit from constraint alerts if present.
        final speedLimitAlert = state.constraintAlerts
            .where((a) => a.startsWith('speed_limit:'))
            .firstOrNull;
        final speedLimitKmh = speedLimitAlert != null
            ? int.tryParse(speedLimitAlert.split(':').last)
            : null;

        final turnCard = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Maneuver icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForCue(nextCue?.maneuver),
                  color: colorScheme.onPrimary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              // Distance + instruction + following
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (distanceText != null) ...[
                      Text(
                        'In $distanceText',
                        style: textTheme.labelLarge?.copyWith(
                          color: onPrimaryFaded,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      instruction,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
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
                            color: onPrimaryFaded,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Then: $followingInstruction',
                              style: textTheme.bodySmall?.copyWith(
                                color: onPrimaryFaded,
                                fontWeight: FontWeight.w500,
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
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recalculating…',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
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
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Off route',
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$speedLimitKmh',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
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

  NavCue? _cueFromFeed(NavState state, int index) {
    if (state.turnFeed.length <= index) return null;
    return state.turnFeed[index];
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavBloc, NavState>(
      builder: (context, state) {
        if (!state.active) return const SizedBox.shrink();

        final remainingTime = _formatRemainingTime(state.remainingSeconds);
        final remainingKm = _formatDistance(state.remainingDistanceM);
        final eta = _formatArrivalTime(context, state.remainingSeconds);

        final textTheme = Theme.of(context).textTheme;

        const bg = AppPalette.capeCodDark02;
        const onBg = AppPalette.white;
        const accent = AppPalette.blueRibbon;
        const subtle = AppPalette.capeCodLight02;

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    debugPrint(
                      '[ActiveNav] turn feed pressed, count=${state.turnFeed.length}',
                    );
                    _showTurnFeedSheet(context);
                  },
                  icon: const Icon(Icons.list_alt, color: onBg),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        remainingTime,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$remainingKm · $eta',
                        style: textTheme.bodySmall?.copyWith(
                          color: subtle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    state.isPaused ? Icons.play_arrow : Icons.pause,
                    color: onBg,
                  ),
                  tooltip: state.isPaused ? 'Resume' : 'Pause',
                  onPressed: () => context.read<NavBloc>().add(
                    state.isPaused ? const NavResume() : const NavPause(),
                  ),
                ),
                IconButton(
                  onPressed: () => context.read<NavBloc>().add(
                    const NavStop(completed: true),
                  ),
                  icon: const Icon(Icons.check_circle, color: accent),
                  tooltip: 'Finish route',
                ),
                IconButton(
                  onPressed: () => context.read<NavBloc>().add(
                    const NavStop(completed: false),
                  ),
                  icon: const Icon(Icons.close, color: subtle),
                  tooltip: 'Cancel',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTurnFeedSheet(BuildContext context) {
    final navBloc = context.read<NavBloc>();
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    showModalBottomSheet(
      context: rootContext,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) =>
          BlocProvider.value(value: navBloc, child: const _TurnFeedSheet()),
    );
  }
}

class _TurnFeedSheet extends StatelessWidget {
  const _TurnFeedSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavBloc, NavState>(
      buildWhen: (prev, curr) => prev.turnFeed != curr.turnFeed,
      builder: (context, state) {
        debugPrint(
          '[ActiveNav] build turn feed sheet count=${state.turnFeed.length}',
        );
        if (state.turnFeed.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No turns available'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.turnFeed.length,
          separatorBuilder: (_, _) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final cue = state.turnFeed[index];
            return InkWell(
              onTap: () {
                final mapBloc = context.read<MapBloc>();
                final mapState = mapBloc.state;
                mapBloc.add(ToggleFollowUser(false));
                mapBloc.add(
                  MapMoved(
                    cue.location,
                    mapState.zoom,
                    force: true,
                    tilt: mapState.tilt,
                    bearing: mapState.bearing,
                  ),
                );
                Navigator.of(context).maybePop();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _iconForCue(cue.maneuver),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cue.instruction,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cue.distanceToCueText.isNotEmpty
                          ? cue.distanceToCueText
                          : '${cue.distanceToCueM.toStringAsFixed(0)} m',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

String _formatRemainingTime(int? seconds) {
  if (seconds == null) return '—';
  final mins = (seconds / 60).round();
  if (mins < 60) return '$mins min';
  final h = (mins / 60).floor();
  final m = mins % 60;
  return '${h}h ${m}m';
}

String _formatDistance(double? meters) {
  if (meters == null) return '— km';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String _formatArrivalTime(BuildContext context, int? seconds) {
  if (seconds == null) return '—';
  final dt = DateTime.now().add(Duration(seconds: seconds));
  final tod = TimeOfDay.fromDateTime(dt);
  return MaterialLocalizations.of(context).formatTimeOfDay(tod);
}
