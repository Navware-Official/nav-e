import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:nav_e/features/nav/bloc/nav_bloc.dart';
import 'package:nav_e/features/nav/bloc/nav_event.dart';
import 'package:nav_e/features/nav/bloc/nav_state.dart';
import 'package:nav_e/features/nav/models/nav_models.dart';
import 'package:nav_e/features/nav/utils/turn_feed.dart';
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
import 'package:nav_e/widgets/user_location_marker.dart';

class ActiveNavScreen extends StatefulWidget {
  final String routeId;
  final List<LatLng> routePoints;

  const ActiveNavScreen({
    super.key,
    required this.routeId,
    required this.routePoints,
  });

  @override
  State<ActiveNavScreen> createState() => _ActiveNavScreenState();
}

class _ActiveNavScreenState extends State<ActiveNavScreen> {
  late final NavBloc _navBloc;

  @override
  void initState() {
    super.initState();
    _navBloc = NavBloc();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _navBloc.add(NavStart(widget.routeId, widget.routePoints));
      _navBloc.add(SetFollowMode(true));
      _navBloc.add(SetTurnFeed(buildTurnFeed(widget.routePoints)));
      final mapBloc = context.read<MapBloc>();
      final mapState = mapBloc.state;
      final locState = context.read<LocationBloc>().state;
      final targetCenter = locState.position ?? mapState.center;
      final targetZoom = mapState.zoom < 17.0 ? 17.0 : mapState.zoom;
      mapBloc.add(ToggleFollowUser(true));
      mapBloc.add(
        MapMoved(
          targetCenter,
          targetZoom,
          force: true,
          tilt: 45.0,
          bearing: locState.heading,
        ),
      );
      try {
        final mapState = context.read<MapBloc>().state;
        context.read<MapBloc>().add(
          ReplacePolylines(
            widget.routePoints.isNotEmpty
                ? [
                    PolylineModel(
                      id: widget.routeId,
                      points: widget.routePoints,
                      colorArgb:
                          mapState.defaultPolylineColorArgb ?? 0xFF375AF9,
                      strokeWidth: mapState.defaultPolylineWidth ?? 4.0,
                    ),
                  ]
                : const [],
            fit: true,
          ),
        );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
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
          BlocListener<NavBloc, NavState>(
            listener: (context, state) {
              if (!state.active) Navigator.of(context).maybePop();

              try {
                if (state.progressPolyline.isNotEmpty) {
                  context.read<MapBloc>().add(
                    ReplacePolylines([
                      PolylineModel(
                        id: '${widget.routeId}-prog',
                        points: state.progressPolyline,
                        colorArgb: AppColors.blueRibbonDark02.value,
                        strokeWidth: 6.0,
                      ),
                    ], fit: false),
                  );
                }
              } catch (_) {}
            },
          ),
          BlocListener<LocationBloc, LocationState>(
            listenWhen: (prev, curr) => prev.heading != curr.heading,
            listener: (context, locState) {
              if (!context.mounted) return;
              final heading = locState.heading;
              if (heading == null) return;
              final mapBloc = context.read<MapBloc>();
              final mapState = mapBloc.state;
              if (!mapState.followUser) return;
              final center = locState.position ?? mapState.center;
              mapBloc.add(
                MapMoved(
                  center,
                  mapState.zoom,
                  force: true,
                  tilt: mapState.tilt,
                  bearing: heading,
                ),
              );
            },
          ),
        ],
        child: BlocBuilder<LocationBloc, LocationState>(
          builder: (context, locState) {
            final markers = <MarkerModel>[
              // User location marker with direction arrow
              if (locState.position != null)
                MarkerModel(
                  id: 'user_location',
                  position: locState.position!,
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

        final primaryText = nextCue?.instruction ?? 'Proceed';
        final secondaryText = followingCue?.instruction ?? '—';

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(12),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _iconForCue(nextCue?.maneuver),
                      color: colorScheme.onPrimary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        primaryText,
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_left,
                      color: colorScheme.onPrimary.withValues(alpha: 0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        secondaryText,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.3),
                  blurRadius: 8,
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
                  icon: const Icon(Icons.list_alt),
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
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$remainingKm · $eta',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => context.read<NavBloc>().add(NavStop()),
                  icon: const Icon(Icons.close),
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
          separatorBuilder: (_, __) => const Divider(height: 16),
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
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
