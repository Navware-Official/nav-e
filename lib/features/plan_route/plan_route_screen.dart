import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/bridge/ffi.dart';
import 'package:nav_e/features/nav/ui/active_nav_screen.dart';

import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/features/map_layers/presentation/map_widget.dart';

class PlanRouteScreen extends StatefulWidget {
  final GeocodingResult destination;

  const PlanRouteScreen({super.key, required this.destination});

  @override
  State<PlanRouteScreen> createState() => _PlanRouteScreenState();
}

class _PlanRouteScreenState extends State<PlanRouteScreen> {
  final MapController _mapController = MapController();
  final String _startSelection = 'Current location';
  LatLng? _manualStart;
  List<LatLng> _routePoints = [];
  double? _distanceM;
  double? _durationS;
  bool _computing = false;
  String? _computeError;

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
      final json = await RustBridge.navComputeRoute(
        dest.lat,
        dest.lon,
        dest.lat,
        dest.lon,
        null,
      );
      final Map<String, dynamic> obj = jsonDecode(json);
      final List wp = obj['waypoints'] as List? ?? [];
      final pts = wp.map<LatLng>((e) {
        final lat = (e[0] as num).toDouble();
        final lon = (e[1] as num).toDouble();
        return LatLng(lat, lon);
      }).toList();
      setState(() {
        _routePoints = pts;
        _distanceM = (obj['distance_m'] as num?)?.toDouble();
        _durationS = (obj['duration_s'] as num?)?.toDouble();
      });

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
      // log and surface error to UI
      debugPrint('Failed to compute route: $e');
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

    // Build markers: destination marker; additional markers (like user) come
    // from map layers or MapBloc.
    final markers = <Marker>[
      Marker(
        point: dest.position,
        width: 45,
        height: 45,
        child: const Icon(Icons.place, color: Color(0xFF3646F4), size: 52),
      ),
    ];

  // Simple polyline: empty for now. Once routing is implemented, populate
  // with decoded polyline coordinates.

  return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: MapWidget(
              mapController: _mapController,
              markers: markers,
              polylines: _routePoints.isNotEmpty
                  ? [
                      Polyline(
                        points: _routePoints,
                        color: Colors.blueAccent,
                        strokeWidth: 4.0,
                      )
                    ]
                  : const [],
            ),
          ),

          // Top floating search-like panel (Google Maps style)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.directions, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Start label (fixed to current location for MVP)
                          const Text(
                            'Current location',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          // Destination label
                          Text(
                            dest.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Nav banner (handled in ActiveNavScreen during active navigation)

          // Bottom sheet with route information
          Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              initialChildSize: 0.28,
              minChildSize: 0.18,
              maxChildSize: 0.9,
              snap: true,
              snapSizes: const [0.28, 0.6, 0.9],
              builder: (context, controller) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 48,
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                            children: [
                            // Compute status / retry area (auto-compute on open)
                            if (_computing) ...[
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              const Text('Computing…'),
                            ] else if (_computeError != null) ...[
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Failed to compute route', style: TextStyle(color: Colors.red))),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _computeRoute,
                              ),
                            ] else if (_routePoints.isNotEmpty) ...[
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Route ready')),
                            ] else ...[
                              const Text('No route'),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _computeRoute,
                              ),
                            ],
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _routePoints.isEmpty || _computing
                                  ? null
                                  : () {
                                      // Open active navigation screen
                                      final id = DateTime.now().millisecondsSinceEpoch.toString();
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => ActiveNavScreen(routeId: id, routePoints: _routePoints),
                                      ));
                                    },
                              icon: const Icon(Icons.navigation),
                              label: const Text('Start'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: controller,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.radio_button_checked),
                              title: Text(_startSelection == 'Current location'
                                  ? 'Start: Current location'
                                  : (_manualStart != null
                                      ? 'Start: ${_manualStart!.latitude.toStringAsFixed(6)}, ${_manualStart!.longitude.toStringAsFixed(6)}'
                                      : 'Start: Selected on map')),
                              subtitle: Text('Destination: ${dest.displayName}'),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.timeline),
                              title: const Text('Route summary'),
                              subtitle: Text(
                                'Distance: ${_distanceM != null ? "${(_distanceM! / 1000).toStringAsFixed(2)} km" : "—"} • ETA: ${_durationS != null ? "${Duration(seconds: _durationS!.toInt()).inMinutes} min" : "—"}',
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              leading: const Icon(Icons.info_outline),
                              title: const Text('Notes'),
                              subtitle: const Text('The route shown is a preview. Tap Start to begin navigation.'),
                            ),
                            const SizedBox(height: 24),

                            // Dump route points for debugging
                            ExpansionTile(
                              leading: const Icon(Icons.code),
                              title: const Text('Route Points (Debug)'),
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  width: double.infinity,
                                  color: Colors.grey[100],
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      _routePoints.map((e) => '[${e.latitude.toStringAsFixed(6)}, ${e.longitude.toStringAsFixed(6)}]').join(', '),
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                    ),
                                  ),
                                ),
                                // Spacer
                                const SizedBox(height: 12),
                                // More debug info could go here
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  width: double.infinity,
                                  color: Colors.grey[100],
                                  child: Text(
                                    'Total Points: ${_routePoints.length}',
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
