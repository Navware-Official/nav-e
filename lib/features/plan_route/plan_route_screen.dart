import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/bridge/lib.dart' as rust;
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/models/marker_model.dart';
import 'package:nav_e/features/map_layers/models/polyline_model.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/plan_route/widgets/plan_route_map.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/map_controls_fab.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/recenter_fab.dart';
import 'package:nav_e/features/plan_route/widgets/route_top_panel.dart';
import 'package:nav_e/features/plan_route/widgets/route_bottom_sheet.dart';
import 'package:nav_e/features/nav/utils/turn_feed.dart';
import 'package:nav_e/features/nav/bloc/nav_bloc.dart';
import 'package:nav_e/features/nav/bloc/nav_event.dart';
import 'package:nav_e/widgets/user_location_marker.dart';

class PlanRouteScreen extends StatefulWidget {
  final GeocodingResult destination;

  const PlanRouteScreen({super.key, required this.destination});

  @override
  State<PlanRouteScreen> createState() => _PlanRouteScreenState();
}

class _PlanRouteScreenState extends State<PlanRouteScreen> {
  static const _routeDebounceDuration = Duration(milliseconds: 400);
  static const bool _useMockRoute = false;

  List<LatLng> _routePoints = [];
  double? _distanceM;
  double? _durationS;
  bool _computing = false;
  String? _computeError;
  // When true the user wants to pick the route start on the map.
  bool _pickOnMap = false;
  // When user picks a start on the map this holds the selected coordinate.
  LatLng? _pickedStart;

  Timer? _routeDebounceTimer;

  @override
  void initState() {
    super.initState();
    _computeRouteDebounced();
  }

  @override
  void dispose() {
    _routeDebounceTimer?.cancel();
    super.dispose();
  }

  /// Schedules a single route fetch after [_routeDebounceDuration]. Cancels
  /// any pending fetch so rapid triggers (e.g. map taps) don't hammer the API.
  Future<void> _computeRouteDebounced() {
    _routeDebounceTimer?.cancel();
    _routeDebounceTimer = Timer(_routeDebounceDuration, () {
      _routeDebounceTimer = null;
      if (mounted) _computeRoute();
    });
    return Future.value();
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

      late final List<LatLng> pts;
      if (_useMockRoute) {
        // Mock polygon-like route data (closed ring-ish) around start/dest
        final mid = LatLng(
          (startPos.latitude + dest.lat) / 2,
          (startPos.longitude + dest.lon) / 2,
        );
        pts = [
          startPos,
          LatLng(startPos.latitude + 0.002, startPos.longitude + 0.003),
          LatLng(mid.latitude + 0.004, mid.longitude - 0.002),
          LatLng(dest.lat + 0.003, dest.lon + 0.002),
          dest.position,
          LatLng(dest.lat - 0.003, dest.lon - 0.002),
          LatLng(mid.latitude - 0.004, mid.longitude + 0.002),
          LatLng(startPos.latitude - 0.002, startPos.longitude - 0.003),
          startPos,
        ];
        _distanceM = null;
        _durationS = null;
      } else {
        // Use the new DDD/CQRS Rust API to calculate route
        // The API returns JSON containing waypoints, distance, duration, and polyline
        final waypoints = [
          (startPos.latitude, startPos.longitude),
          (dest.lat, dest.lon),
        ];
        final json = await rust.calculateRoute(waypoints: waypoints);
        // Log the raw JSON for debugging - this can be removed once we're confident in the API and data structure.
        debugPrint('[PlanRouteScreen] Route JSON: $json');
        final Map<String, dynamic> obj = jsonDecode(json);
        final polylineJson = obj['polyline_json'] as String?;
        if (polylineJson != null && polylineJson.isNotEmpty) {
          final List<dynamic> poly = jsonDecode(polylineJson) as List<dynamic>;
          pts = poly.map<LatLng>((e) {
            final lat = (e[0] as num).toDouble();
            final lon = (e[1] as num).toDouble();
            return LatLng(lat, lon);
          }).toList();
        } else {
          final List wp = obj['waypoints'] as List? ?? [];
          pts = wp.map<LatLng>((e) {
            final lat = (e['latitude'] as num).toDouble();
            final lon = (e['longitude'] as num).toDouble();
            return LatLng(lat, lon);
          }).toList();
        }
        _distanceM = (obj['distance_meters'] as num?)?.toDouble();
        _durationS = (obj['duration_seconds'] as num?)?.toDouble();
      }

      if (pts.length < 2) {
        // Not enough points to draw a line — surface this to the UI so the
        // user/developer can see that the computed route is too small.
        setState(() {
          _computeError =
              'Route contains only ${pts.length} waypoint(s); need at least 2 to display a line.';
        });
      } else {
        // Clear any previous compute error when we have a valid route.
        setState(() {
          _computeError = null;
        });
      }
      setState(() {
        _routePoints = pts;
      });

      if (!mounted) return;
      final turnFeed = buildTurnFeed(pts);
      try {
        context.read<NavBloc>().add(SetTurnFeed(turnFeed));
      } catch (_) {
        // NavBloc not available in this context; ignore
      }

      // Convert to a lightweight PolylineModel and push to MapBloc so the
      // map renders the polyline via the shared map state. This is useful
      // as a fallback path and keeps rendering consistent with other
      // polylines in the app. Use MapBloc style config when set.
      final mapState = context.read<MapBloc>().state;
      final model = PolylineModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        points: pts,
        colorArgb: mapState.defaultPolylineColorArgb ?? 0xFF375AF9,
        strokeWidth: mapState.defaultPolylineWidth ?? 4.0,
      );
      if (mounted) {
        try {
          // Auto-fit the route with padding - MapWidget handles this via autoFit flag
          context.read<MapBloc>().add(ReplacePolylines([model], fit: true));
        } catch (_) {
          // If MapBloc isn't available in this context for some reason,
          // ignore and continue — the inline polyline remains a fallback.
        }
      }
    } catch (e) {
      // surface error to UI
      setState(() {
        _computeError = e.toString();
      });
    } finally {
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
        startLabel =
            'Picked: ${_pickedStart!.latitude.toStringAsFixed(5)}, ${_pickedStart!.longitude.toStringAsFixed(5)}';
      } else {
        startLabel = 'Tap map to pick start';
      }
    } else {
      if (userPos != null) {
        startLabel =
            'Current: ${userPos.latitude.toStringAsFixed(5)}, ${userPos.longitude.toStringAsFixed(5)}';
      } else {
        startLabel = 'Current location';
      }
    }
    final markers = <MarkerModel>[
      // Destination marker
      MarkerModel(
        id: 'destination',
        position: dest.position,
        icon: const Icon(Icons.place, color: AppColors.blueRibbon, size: 52),
      ),
      // Current location marker with direction arrow
      if (userPos != null)
        MarkerModel(
          id: 'current_location',
          position: userPos,
          icon: UserLocationMarker(
            heading: context.watch<LocationBloc>().state.heading,
          ),
        ),
      // If the user picked a custom start on the map, show it as a marker.
      if (_pickedStart != null)
        MarkerModel(
          id: 'picked_start',
          position: _pickedStart!,
          icon: Builder(
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              return Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colorScheme.tertiary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
              );
            },
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
              markers: markers,
              polylines: _routePoints.isNotEmpty
                  ? [
                      PolylineModel(
                        id: 'route',
                        points: _routePoints,
                        colorArgb:
                            context
                                .read<MapBloc>()
                                .state
                                .defaultPolylineColorArgb ??
                            0xFF375AF9,
                        strokeWidth:
                            context
                                .read<MapBloc>()
                                .state
                                .defaultPolylineWidth ??
                            4.0,
                      ),
                    ]
                  : const [],
              onMapTap: (latlng) {
                if (!_pickOnMap) return;
                setState(() {
                  _pickedStart = latlng;
                });
                _computeRouteDebounced();
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
                if (!v) {
                  _pickedStart =
                      null; // clear any picked start when switching back
                }
              });
              if (!v) {
                _computeRouteDebounced();
              }
            },
            startLabel: startLabel,
          ),

          // Map control widgets (same as HomeView)
          const RecenterFAB(),
          const MapControlsFAB(),

          // Bottom sheet
          RouteBottomSheet(
            destination: dest,
            computing: _computing,
            computeError: _computeError,
            routePoints: _routePoints,
            distanceM: _distanceM,
            durationS: _durationS,
            onCompute: _computeRouteDebounced,
          ),
        ],
      ),
    );
  }
}
