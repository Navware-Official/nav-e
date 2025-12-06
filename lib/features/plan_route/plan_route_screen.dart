import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/bridge/lib.dart' as bridge;
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/models/polyline_model.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/plan_route/widgets/plan_route_map.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/map_controls_fab.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/rotate_north_fab.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/recenter_fab.dart';
import 'package:nav_e/features/plan_route/widgets/route_top_panel.dart';
import 'package:nav_e/features/plan_route/widgets/route_bottom_sheet.dart';


class PlanRouteScreen extends StatefulWidget {
  final GeocodingResult destination;

  const PlanRouteScreen({super.key, required this.destination});

  @override
  State<PlanRouteScreen> createState() => _PlanRouteScreenState();
}

class _PlanRouteScreenState extends State<PlanRouteScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  double? _distanceM;
  double? _durationS;
  bool _computing = false;
  String? _computeError;
  // When true the user wants to pick the route start on the map.
  bool _pickOnMap = false;
  // When user picks a start on the map this holds the selected coordinate.
  LatLng? _pickedStart;

  @override
  void initState() {
    super.initState();
    // Compute the route immediately (stub will ignore coordinates and return
    // a hardcoded route). Using destination as end; start is placeholder.
    _computeRoute();
  }

  Future<void> _computeRoute() async {
    setState(() {
      _computing = true;
      _computeError = null;
    });
    try {
      final dest = widget.destination;
      // Determine start position based on user selection:
      // - If pick-on-map is active and the user selected a point, use that.
      // - Otherwise prefer GPS (LocationBloc), then map center, then dest.
      LatLng startPos = LatLng(dest.lat, dest.lon);
      if (_pickOnMap && _pickedStart != null) {
        startPos = _pickedStart!;
      } else {
      try {
        final locState = context.read<LocationBloc>().state;
        if (locState.position != null) {
          startPos = locState.position!;
        } else {
          // Fall back to map center if LocationBloc has no position yet.
          try {
            startPos = context.read<MapBloc>().state.center;
          } catch (_) {
            // keep default (dest)
          }
        }
      } catch (_) {
        // If LocationBloc isn't provided in this context, attempt MapBloc
        // center and otherwise keep destination as a last resort.
        try {
          startPos = context.read<MapBloc>().state.center;
        } catch (_) {
          // keep dest
        }
      }
      }

      final json = await bridge.navComputeRoute(
        startLat: startPos.latitude,
        startLon: startPos.longitude,
        endLat: dest.lat,
        endLon: dest.lon,
        options: null,
      );
      final Map<String, dynamic> obj = jsonDecode(json);
      final List wp = obj['waypoints'] as List? ?? [];
      final pts = wp.map<LatLng>((e) {
        final lat = (e[0] as num).toDouble();
        final lon = (e[1] as num).toDouble();
        return LatLng(lat, lon);
      }).toList();
      
      if (pts.length < 2) {
        // Not enough points to draw a line — surface this to the UI so the
        // user/developer can see that the computed route is too small.
        setState(() {
          _computeError = 'Route contains only ${pts.length} waypoint(s); need at least 2 to display a line.';
        });
      } else {
        // Clear any previous compute error when we have a valid route.
        setState(() {
          _computeError = null;
        });
      }
      setState(() {
        _routePoints = pts;
        _distanceM = (obj['distance_m'] as num?)?.toDouble();
        _durationS = (obj['duration_s'] as num?)?.toDouble();
      });

      // Convert to a lightweight PolylineModel and push to MapBloc so the
      // map renders the polyline via the shared map state. This is useful
      // as a fallback path and keeps rendering consistent with other
      // polylines in the app.
      final model = PolylineModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        points: pts,
        colorArgb: 0xFFE53935, // red-ish accent
        strokeWidth: 6.0,
      );
      if (mounted) {
        try {
          context.read<MapBloc>().add(ReplacePolylines([model], fit: true));
        } catch (_) {
          // If MapBloc isn't available in this context for some reason,
          // ignore and continue — the inline polyline remains a fallback.
        }
      }

      // Adjust camera to fit the route with reasonable padding so the top
      // overlay and bottom sheet do not cover the line.
      if (_routePoints.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            final mq = MediaQuery.of(context);
            final pad = EdgeInsets.only(
              left: 12,
              right: 12,
              top: mq.padding.top + 88, // space for top overlay
              bottom: mq.padding.bottom + 220, // space for bottom sheet
            );
            final fit = CameraFit.coordinates(
              coordinates: _routePoints,
              maxZoom: 17,
              padding: pad,
            );
            _mapController.fitCamera(fit);
          } catch (e) {
            // Fallback: move to first point with a reasonable zoom.
            final p = _routePoints.first;
            _mapController.move(p, 14);
          }
        });
      }
    } catch (e) {
      // surface error to UI
      setState(() {
        _computeError = e.toString();
      });
    }
    finally {
      setState(() {
        _computing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.destination;

    // Build markers: destination marker and (when available) the user's
    // current GPS position marker. We watch `LocationBloc` so the marker
    // appears/updates as the position becomes available.
    final userPos = context.watch<LocationBloc>().state.position;

    // Compute a human-friendly label for the start source to show in the
    // top panel. This updates when the user toggles pick-on-map and when
    // they tap the map to pick a start location.
    final String startLabel;
    if (_pickOnMap) {
      if (_pickedStart != null) {
        startLabel = 'Picked: ${_pickedStart!.latitude.toStringAsFixed(5)}, ${_pickedStart!.longitude.toStringAsFixed(5)}';
      } else {
        startLabel = 'Tap map to pick start';
      }
    } else {
      if (userPos != null) {
        startLabel = 'Current: ${userPos.latitude.toStringAsFixed(5)}, ${userPos.longitude.toStringAsFixed(5)}';
      } else {
        startLabel = 'Current location';
      }
    }
    final markers = <Marker>[
      Marker(
        point: dest.position,
        width: 45,
        height: 45,
        child: const Icon(Icons.place, color: Color(0xFF3646F4), size: 52),
      ),
      if (userPos != null)
        Marker(
          point: userPos,
          width: 28,
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const SizedBox.shrink(),
          ),
        ),
      // If the user picked a custom start on the map, show it as a marker.
      if (_pickedStart != null)
        Marker(
          point: _pickedStart!,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const SizedBox.shrink(),
          ),
        ),
    ];

  // Build the main scaffold composed from smaller widgets in the widgets/
  // subfolder. This keeps layout code modular and easier to maintain.

  return Scaffold(
    extendBodyBehindAppBar: true,
    body: Stack(
      children: [
        // Map
        Positioned.fill(
          child: PlanRouteMap(
            mapController: _mapController,
            markers: markers,
            polylines: _routePoints.isNotEmpty
                ? [
                    Polyline(
                      points: _routePoints,
                      color: AppColors.blueRibbonDark02,
                      strokeWidth: 6.0,
                    )
                  ]
                : const [],
            onMapTap: (latlng) {
              if (!_pickOnMap) return;
              // set picked start and compute route immediately
              setState(() {
                _pickedStart = latlng;
              });
              _computeRoute();
            },
          ),
        ),

  // Top panel
  RouteTopPanel(
    destination: dest,
    pickOnMap: _pickOnMap,
    onPickOnMapChanged: (v) {
      setState(() {
        _pickOnMap = v;
        if (!v) _pickedStart = null; // clear any picked start when switching back
      });
      // When switching back to 'Current location', automatically recompute
      // the route using the current GPS/map center to give immediate
      // feedback (button will enter the computing/loading state).
      if (!v) {
        _computeRoute();
      }
    },
    startLabel: startLabel,
  ),

  // Reuse the mini map control widgets (same as HomeView) so users
  // can re-center, rotate north, or open map controls while planning
  // a route.
  RecenterFAB(mapController: _mapController),
  RotateNorthFAB(mapController: _mapController),
  const MapControlsFAB(),

  // Bottom sheet
        RouteBottomSheet(
          destination: dest,
          computing: _computing,
          computeError: _computeError,
          routePoints: _routePoints,
          distanceM: _distanceM,
          durationS: _durationS,
          onCompute: _computeRoute,
        ),
      ],
    ),
  );
  }

}
