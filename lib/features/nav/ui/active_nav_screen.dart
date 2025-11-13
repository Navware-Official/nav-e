import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:nav_e/features/nav/bloc/nav_bloc.dart';
import 'package:nav_e/features/nav/bloc/nav_event.dart';
import 'package:nav_e/features/nav/bloc/nav_state.dart';
import 'package:nav_e/features/nav/ui/nav_banner.dart';
import 'package:nav_e/features/map_layers/presentation/map_widget.dart';
import 'package:nav_e/features/map_layers/models/polyline_model.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';

class ActiveNavScreen extends StatefulWidget {
  final String routeId;
  final List<LatLng> routePoints;

  const ActiveNavScreen({super.key, required this.routeId, required this.routePoints});

  @override
  State<ActiveNavScreen> createState() => _ActiveNavScreenState();
}

class _ActiveNavScreenState extends State<ActiveNavScreen> {
  late final NavBloc _navBloc;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _navBloc = NavBloc();
    // start navigation right away
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _navBloc.add(NavStart(widget.routeId, widget.routePoints));
      _navBloc.add(SetFollowMode(true));
      // publish route polyline to MapBloc and request auto-fit
      try {
        context.read<MapBloc>().add(ReplacePolylines(
          widget.routePoints.isNotEmpty
              ? [
                  // convert to model
                  PolylineModel(id: widget.routeId, points: widget.routePoints, colorArgb: 0xFF2196F3, strokeWidth: 4.0)
                ]
              : const [],
          fit: true,
        ));
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
          // if navigation ends, pop the screen
          if (!state.active) Navigator.of(context).maybePop();

          // publish progress polyline updates to the MapBloc (lightweight)
          try {
            if (state.progressPolyline.isNotEmpty) {
              context.read<MapBloc>().add(ReplacePolylines([
                PolylineModel(id: '${widget.routeId}-prog', points: state.progressPolyline, colorArgb: 0xFF64B5F6, strokeWidth: 6.0)
              ], fit: false));
            }
          } catch (_) {}
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              Positioned.fill(
                child: MapWidget(
                  mapController: _mapController,
                  markers: const [],
                  polylines: widget.routePoints.isNotEmpty
                      ? [
                          Polyline(
                            points: widget.routePoints,
                            color: Colors.blueAccent,
                            strokeWidth: 4.0,
                          ),
                        ]
                      : const [],
                ),
              ),
              // minimal top banner for turns / next cue
              const Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: NavBanner(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
