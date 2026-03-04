import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/features/location_preview/cubit/preview_cubit.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';

/// Handles URL parameter changes and coordinates preview/map state updates.
class RouteParamsHandler {
  VoidCallback? _routerListener;
  GoRouter? _router;
  String? _lastUriString;
  String? _lastHandledRouteKey;
  bool _handlingRoute = false;
  bool _mapReady = false;
  bool _listenerAdded = false;
  final Set<String> _dismissedRouteKeys = {};

  /// Initializes route parameter handling for the given context.
  void initialize(BuildContext context) {
    _router = GoRouter.maybeOf(context);

    // Handle initial route parameters (once per route)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final uri = GoRouterState.of(context).uri;
      _lastUriString = uri.toString();
      _handleRouteParams(context, uri);
    });

    // Listen for route changes - only add listener once to avoid duplicate callbacks
    if (_listenerAdded || _router == null) return;
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
    _router!.routerDelegate.addListener(_routerListener!);
    _listenerAdded = true;
  }

  /// Updates the map ready state.
  void setMapReady(bool ready) {
    _mapReady = ready;
  }

  /// Cleans up the route listener. Call without context (uses stored router reference).
  void removeListener() {
    if (_routerListener != null && _listenerAdded && _router != null) {
      _router!.routerDelegate.removeListener(_routerListener!);
      _listenerAdded = false;
    }
    _routerListener = null;
    _router = null;
  }

  /// Cleans up the route listener and handler state.
  void dispose() {
    removeListener();
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
      _dismissedRouteKeys.clear();
      debugPrint('[RouteParamsHandler] Missing lat/lon/label. Skip.');
      return;
    }

    // Generate unique key to avoid duplicate processing
    final key = _generateRouteKey(lat, lon, label, qp['placeId']);
    if (_lastHandledRouteKey == key) return;
    if (_dismissedRouteKeys.contains(key)) return;

    _handlingRoute = true;
    try {
      // Wait for map to be ready before showing preview
      await _waitForMapReady(context);
      if (!context.mounted) return;

      // User may have closed the preview while we were waiting; do not re-open
      if (_dismissedRouteKeys.contains(key)) return;

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

  /// Clears preview URL parameters by navigating to Explore (map) with no query params.
  /// Keeps the user on the map tab; use this when preview is shown from URL params.
  static void clearPreviewParams(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go('/');
      }
    });
  }

  /// Call when the user dismisses the location preview so a delayed _handleRouteParams
  /// does not re-open it (e.g. after _waitForMapReady completes).
  void markPreviewDismissed(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final qp = uri.queryParameters;
    final lat = double.tryParse(qp['lat'] ?? '');
    final lon = double.tryParse(qp['lon'] ?? '');
    final label = qp['label'];
    if (lat != null && lon != null && label != null) {
      _dismissedRouteKeys.add(
        _generateRouteKey(lat, lon, label, qp['placeId']),
      );
    }
  }
}
