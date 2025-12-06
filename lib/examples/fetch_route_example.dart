/// Example: Fetching and Using Route Data
///
/// Shows how to use the clean DDD API to calculate routes and access route data
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nav_e/bridge/api_v2.dart' as api;

/// Simple example of fetching a route
class FetchRouteExample extends StatefulWidget {
  const FetchRouteExample({Key? key}) : super(key: key);

  @override
  State<FetchRouteExample> createState() => _FetchRouteExampleState();
}

class _FetchRouteExampleState extends State<FetchRouteExample> {
  String? _routeJson;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Fetching Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _fetchRoute,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Calculate Route'),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: $_error',
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ),
            if (_routeJson != null) ...[
              const Text(
                'Route Data:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildRouteInfo(),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Fetch a route between two points
  Future<void> _fetchRoute() async {
    setState(() {
      _loading = true;
      _error = null;
      _routeJson = null;
    });

    try {
      // Define waypoints: (latitude, longitude)
      final waypoints = [
        (37.7749, -122.4194), // San Francisco
        (37.8044, -122.2711), // Oakland
      ];

      // Call the Rust API
      final routeJson = await api.calculateRoute(waypoints: waypoints);

      setState(() {
        _routeJson = routeJson;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Parse and display route information
  Widget _buildRouteInfo() {
    if (_routeJson == null) return const SizedBox.shrink();

    try {
      final route = jsonDecode(_routeJson!) as Map<String, dynamic>;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Route ID', route['id'] ?? 'N/A'),
          _infoRow('Distance', '${route['distance_meters'] ?? 0} meters'),
          _infoRow('Duration', '${route['duration_seconds'] ?? 0} seconds'),
          const SizedBox(height: 16),
          const Text(
            'Waypoints:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (route['waypoints'] != null)
            ...List.generate(
              (route['waypoints'] as List).length,
              (index) {
                final wp = route['waypoints'][index];
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                  child: Text(
                    '${index + 1}. ${wp['name'] ?? 'Waypoint'}: '
                    '(${wp['latitude']}, ${wp['longitude']})',
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          if (route['polyline_json'] != null) ...[
            const Text(
              'Route Polyline:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Contains ${(jsonDecode(route['polyline_json']) as List).length} points',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ],
      );
    } catch (e) {
      return Text('Error parsing route: $e');
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Complete Navigation Flow Example
class NavigationFlowExample extends StatefulWidget {
  const NavigationFlowExample({Key? key}) : super(key: key);

  @override
  State<NavigationFlowExample> createState() => _NavigationFlowExampleState();
}

class _NavigationFlowExampleState extends State<NavigationFlowExample> {
  String? _sessionId;
  String? _activeSession;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation Flow Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _startNavigation,
              child: const Text('Start Navigation'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _sessionId == null || _loading ? null : _updatePosition,
              child: const Text('Update Position'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _sessionId == null || _loading ? null : _pauseNavigation,
              child: const Text('Pause Navigation'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _sessionId == null || _loading ? null : _resumeNavigation,
              child: const Text('Resume Navigation'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _sessionId == null || _loading ? null : _stopNavigation,
              child: const Text('Stop Navigation'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _checkActiveSession,
              child: const Text('Check Active Session'),
            ),
            const SizedBox(height: 20),
            if (_sessionId != null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Session:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Session ID: $_sessionId'),
                    ],
                  ),
                ),
              ),
            if (_activeSession != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Session Data:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_activeSession!),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNavigation() async {
    setState(() => _loading = true);
    try {
      final waypoints = [
        (37.7749, -122.4194), // San Francisco
        (37.8044, -122.2711), // Oakland
      ];
      final currentPosition = (37.7749, -122.4194);

      final sessionJson = await api.startNavigationSession(
        waypoints: waypoints,
        currentPosition: currentPosition,
      );

      final session = jsonDecode(sessionJson) as Map<String, dynamic>;
      setState(() {
        _sessionId = session['id'];
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigation started!')),
      );
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  Future<void> _updatePosition() async {
    if (_sessionId == null) return;

    setState(() => _loading = true);
    try {
      // Simulate moving closer to destination
      await api.updateNavigationPosition(
        sessionId: _sessionId!,
        latitude: 37.7800,
        longitude: -122.4000,
      );

      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Position updated!')),
      );
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  Future<void> _pauseNavigation() async {
    if (_sessionId == null) return;

    setState(() => _loading = true);
    try {
      await api.pauseNavigation(sessionId: _sessionId!);
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigation paused!')),
      );
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  Future<void> _resumeNavigation() async {
    if (_sessionId == null) return;

    setState(() => _loading = true);
    try {
      await api.resumeNavigation(sessionId: _sessionId!);
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigation resumed!')),
      );
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  Future<void> _stopNavigation() async {
    if (_sessionId == null) return;

    setState(() => _loading = true);
    try {
      await api.stopNavigation(sessionId: _sessionId!, completed: true);
      setState(() {
        _sessionId = null;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigation stopped!')),
      );
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  Future<void> _checkActiveSession() async {
    setState(() => _loading = true);
    try {
      final sessionJson = await api.getActiveSession();
      setState(() {
        _activeSession = sessionJson ?? 'No active session';
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $message'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
