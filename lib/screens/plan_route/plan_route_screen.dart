import 'package:flutter/material.dart';
import 'package:nav_e/models/geocoding_result.dart';

class PlanRouteScreen extends StatelessWidget {
  final GeocodingResult destination;

  const PlanRouteScreen({
    super.key,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final startController = TextEditingController();
    final endController = TextEditingController(text: destination.displayName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan a Route'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Save Route',
            onPressed: () {
              // Implement save route functionality here
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.directions, size: 32),
                SizedBox(width: 12),
                Text(
                  'Route Planner',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                TextField(
                  controller: startController,
                  decoration: const InputDecoration(
                    labelText: 'Start',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endController,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
