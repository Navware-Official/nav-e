import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/features/location_preview/cubit/preview_cubit.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';

/// Handles URL parameter changes and coordinates preview/map state updates.
class RouteParamsHandler {
  VoidCallback? _routerListener;
  String? _lastUriString;
  String? _lastHandledRouteKey;
  bool _handlingRoute = false;
  bool _mapReady = false;

  /// Initializes route parameter handling for the given context.
  void initialize(BuildContext context) {
    // Handle initial route parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final uri = GoRouterState.of(context).uri;
      _lastUriString = uri.toString();
      _handleRouteParams(context, uri);
    });

    // Listen for route changes
    final router = GoRouter.of(context);
    _routerListener ??= () {
      if (!context.mounted) return;
      final uri = GoRouterState.of(context).uri;
      final currentUriString = uri.toString();

      // Skip if URI hasn't changed
      if (_lastUriString == currentUriString) return;

      final previousUriString = _lastUriString;
      _lastUriString = currentUriString;

      _handleRouteParams(context, uri);
      _handlePolylineCleanup(context, uri, previousUriString);
    };
    router.routerDelegate.addListener(_routerListener!);
  }

  /// Updates the map ready state.
  void setMapReady(bool ready) {
    _mapReady = ready;
  }

  /// Cleans up the route listener.
  void dispose() {
    _routerListener = null;
  }

  /// Removes the listener from the router.
  void removeListener(BuildContext context) {
    if (_routerListener != null) {
      GoRouter.of(context).routerDelegate.removeListener(_routerListener!);
    }
  }

  /// Handles route parameters and triggers location preview if valid coords are present.
  Future<void> _handleRouteParams(BuildContext context, Uri uri) async {
    if (_handlingRoute) return;

    final qp = uri.queryParameters;
    final lat = double.tryParse(qp['lat'] ?? '');
    final lon = double.tryParse(qp['lon'] ?? '');
    final label = qp['label'];

    // Skip if required parameters are missing
    if (lat == null || lon == null || label == null) {
      debugPrint('[RouteParamsHandler] Missing lat/lon/label. Skip.');
      return;
    }

    // Generate unique key to avoid duplicate processing
    final key = _generateRouteKey(lat, lon, label, qp['placeId']);
    if (_lastHandledRouteKey == key) return;

    _handlingRoute = true;
    try {
      // Wait for map to be ready before showing preview
      await _waitForMapReady(context);
      if (!context.mounted) return;

      _lastHandledRouteKey = key;

      // Trigger location preview
      context.read<PreviewCubit>().showCoords(
        lat: lat,
        lon: lon,
        label: label,
        placeId: qp['placeId'],
      );
    } finally {
      _handlingRoute = false;
    }
  }

  /// Clears polylines when returning from plan-route screen to plain home route.
  void _handlePolylineCleanup(
    BuildContext context,
    Uri currentUri,
    String? previousUriString,
  ) {
    // Only clear polylines when returning to plain home route
    final isPlainHomeRoute =
        currentUri.path == '/' && currentUri.queryParameters.isEmpty;
    final comingFromPlanRoute =
        previousUriString != null && previousUriString.contains('/plan-route');

    if (isPlainHomeRoute && comingFromPlanRoute) {
      try {
        context.read<MapBloc>().add(ReplacePolylines(const [], fit: false));
      } catch (_) {
        // MapBloc not available, ignore silently
      }
    }
  }

  /// Waits for the map to be ready with a timeout.
  Future<void> _waitForMapReady(BuildContext context) async {
    const maxWaitTime = Duration(seconds: 5);
    const pollInterval = Duration(milliseconds: 30);
    final startTime = DateTime.now();

    while (context.mounted && !_mapReady) {
      if (DateTime.now().difference(startTime) > maxWaitTime) {
        debugPrint('[RouteParamsHandler] Map ready timeout');
        break;
      }
      await Future.delayed(pollInterval);
    }
  }

  /// Generates a unique key for route parameters to avoid duplicate processing.
  String _generateRouteKey(
    double lat,
    double lon,
    String label,
    String? placeId,
  ) {
    return '${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}|$label|${placeId ?? ''}';
  }

  /// Clears preview URL parameters by navigating to plain home route.
  static void clearPreviewParams(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.goNamed('home', queryParameters: const {});
      }
    });
  }
}
