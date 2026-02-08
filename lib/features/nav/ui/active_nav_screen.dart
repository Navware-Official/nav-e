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
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/core/theme/colors.dart';

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
      try {
        context.read<MapBloc>().add(
          ReplacePolylines(
            widget.routePoints.isNotEmpty
                ? [
                    PolylineModel(
                      id: widget.routeId,
                      points: widget.routePoints,
                      colorArgb: AppColors.blueRibbon.value,
                      strokeWidth: 4.0,
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
    _navBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _navBloc,
      child: BlocListener<NavBloc, NavState>(
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
        child: Scaffold(
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              Positioned.fill(child: const MapWidget(markers: [])),
              const Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _TopTurnBar(),
              ),
              const Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _BottomNavBar(),
              ),
            ],
          ),
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

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _iconForCue(nextCue?.maneuver),
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        primaryText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
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
                    const Icon(
                      Icons.subdirectory_arrow_left,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        secondaryText,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
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

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8),
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$remainingKm · $eta',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
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
      builder: (_) => BlocProvider.value(
        value: navBloc,
        child: const _TurnFeedSheet(),
      ),
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
        debugPrint('[ActiveNav] build turn feed sheet count=${state.turnFeed.length}');
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
            return Row(
              children: [
                Icon(_iconForCue(cue.maneuver), color: Colors.blueGrey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cue.instruction,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${cue.distanceToCueM.toStringAsFixed(0)} m'),
              ],
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
  if (mins < 60) return '${mins} min';
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
