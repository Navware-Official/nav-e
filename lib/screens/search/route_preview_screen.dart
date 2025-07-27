import 'package:flutter/material.dart';
import 'package:nav_e/services/geocoding_service.dart';

class RoutePreviewScreen extends StatelessWidget {
  const RoutePreviewScreen({super.key, required GeocodingResult destination});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Preview'),
      ),
      body: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions, size: 48),
            SizedBox(width: 16),
            Text('Route to destination', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}