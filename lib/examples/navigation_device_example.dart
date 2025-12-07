/// Example: Complete Navigation Flow with Device Communication
/// 
/// This example shows how to use the new DDD/Hexagonal/CQRS architecture API.
/// Device communication is now handled on the Rust side via Protocol Buffers.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nav_e/bridge/api_v2.dart' as api;

/// Example: Navigation with Device Sync
class NavigationWithDeviceExample extends StatefulWidget {
  const NavigationWithDeviceExample({Key? key}) : super(key: key);

  @override
  State<NavigationWithDeviceExample> createState() =>
      _NavigationWithDeviceExampleState();
}

class _NavigationWithDeviceExampleState
    extends State<NavigationWithDeviceExample> {
  String? _sessionId;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // All device communication is now handled in Rust via the clean API
  }



  /// Start navigation using the clean Rust API
  Future<void> _startNavigation() async {
    try {
      final waypoints = [
        (52.5200, 13.4050), // Berlin start
        (52.5300, 13.4150), // Berlin end
      ];
      final currentPosition = (52.5200, 13.4050);

      await api.startNavigationSession(
        waypoints: waypoints,
        currentPosition: currentPosition,
      );

      setState(() {
        _isNavigating = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigation started via Rust API!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Update current position via Rust API
  Future<void> _updatePosition(double lat, double lon) async {
    if (_sessionId == null) return;

    try {
      await api.updateNavigationPosition(
        sessionId: _sessionId!,
        latitude: lat,
        longitude: lon,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation API Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _isNavigating ? Icons.navigation : Icons.location_off,
                      size: 48,
                      color: _isNavigating ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isNavigating ? 'Navigation Active' : 'Not Navigating',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isNavigating ? null : _startNavigation,
              icon: const Icon(Icons.navigation),
              label: const Text('Start Navigation'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isNavigating ? () => _updatePosition(52.5250, 13.4100) : null,
              icon: const Icon(Icons.my_location),
              label: const Text('Update Position'),
            ),
            const Spacer(),
            const Text(
              'This example uses the clean Rust API.\nDevice communication is handled on the Rust side.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
