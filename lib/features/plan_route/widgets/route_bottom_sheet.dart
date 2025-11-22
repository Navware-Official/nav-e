import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
// imports above (map bloc/models) are intentionally omitted; this widget is
// presentation-only and receives state + callbacks from the parent screen.
import 'package:nav_e/features/nav/ui/active_nav_screen.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';

typedef ComputeRouteCallback = Future<void> Function();

class RouteBottomSheet extends StatelessWidget {
  final GeocodingResult destination;
  final bool computing;
  final String? computeError;
  final List<LatLng> routePoints;
  final double? distanceM;
  final double? durationS;
  final ComputeRouteCallback onCompute;
  

  const RouteBottomSheet({
    super.key,
    required this.destination,
    required this.computing,
    required this.computeError,
    required this.routePoints,
    required this.distanceM,
    required this.durationS,
  required this.onCompute,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
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
                  child: Row(children: [
                    if (computing) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      const Text('Computing…'),
                    ] else if (computeError != null) ...[
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Failed to compute route', style: TextStyle(color: Colors.red))),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: onCompute,
                      ),
                    ] else if (routePoints.isNotEmpty) ...[
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Route ready')),
                    ] else ...[
                      const Text('No route'),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: onCompute,
                      ),
                    ],
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: routePoints.isEmpty || computing
                          ? null
                          : () {
                              final id = DateTime.now().millisecondsSinceEpoch.toString();
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ActiveNavScreen(routeId: id, routePoints: routePoints),
                              ));
                            },
                      icon: const Icon(Icons.navigation),
                      label: const Text('Start'),
                    ),
                    // debug injection removed
                  ]),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.radio_button_checked),
                        title: Text(routePoints.isEmpty ? 'Start: Current location' : 'Start: Current location'),
                        subtitle: Text('Destination: ${destination.displayName}'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.timeline),
                        title: const Text('Route summary'),
                        subtitle: Text(
                          'Distance: ${distanceM != null ? "${(distanceM! / 1000).toStringAsFixed(2)} km" : "—"} • ETA: ${durationS != null ? "${Duration(seconds: durationS!.toInt()).inMinutes} min" : "—"}',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Notes'),
                        subtitle: const Text('The route shown is a preview. Tap Start to begin navigation.'),
                      ),
                      const SizedBox(height: 24),
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
                                routePoints.map((e) => '[${e.latitude.toStringAsFixed(6)}, ${e.longitude.toStringAsFixed(6)}]').join(', '),
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            width: double.infinity,
                            color: Colors.grey[100],
                            child: Text(
                              'Error message from last compute: ${computeError ?? "None"}',
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
    );
  }
}
