import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';
import 'package:nav_e/features/device_management/add_device_screen.dart';
import 'package:nav_e/features/device_management/device_management_screen.dart';
import 'package:nav_e/features/device_comm/presentation/screens/device_comm_debug_screen.dart';

import 'package:nav_e/features/home/home_screen.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/domain/entities/saved_route.dart';
import 'package:nav_e/features/plan_route/plan_route_screen.dart';
import 'package:nav_e/features/saved_places/saved_places_screen.dart';
import 'package:nav_e/features/saved_routes/import_preview_screen.dart';
import 'package:nav_e/features/saved_routes/saved_routes_screen.dart';
import 'package:nav_e/features/search/bloc/search_bloc.dart';
import 'package:nav_e/features/search/search_screen.dart';
import 'package:nav_e/features/settings/settings_screen.dart';
import 'package:nav_e/features/settings/licenses_screen.dart';
import 'package:nav_e/features/offline_maps/presentation/offline_maps_screen.dart';
import 'package:nav_e/features/nav/ui/route_finish_screen.dart';
import 'package:nav_e/core/domain/entities/trip.dart';
import 'package:nav_e/features/trip_history/trip_history_screen.dart';
import 'package:nav_e/features/trip_history/trip_detail_screen.dart';
import 'package:nav_e/features/home/dashboard/home_dashboard_screen.dart';
import 'package:nav_e/features/plan/plan_screen.dart';
import 'package:nav_e/features/profile/profile_screen.dart';
import 'package:nav_e/app/app_shell.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter({Listenable? refreshListenable}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (BuildContext context, GoRouterState state) {
      if (state.uri.path == '/plan-route') {
        final g = GeocodingResult.fromPathParams(state.uri.queryParameters);
        if (g == null) return '/';
      }
      if (state.uri.path == '/plan-route/saved' && state.extra == null)
        return '/';
      if (state.uri.path == '/trip-detail' && state.extra == null) return '/';
      if (state.uri.path == '/route-finish' && state.extra == null) return '/';
      if (state.uri.path == '/device-comm-debug' && state.extra == null)
        return '/';
      if (state.error != null) return '/';
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (_, __) => const HomeDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'explore',
                builder: (ctx, state) => HomeScreen(
                  placeId: state.uri.queryParameters['placeId'],
                  latParam: state.uri.queryParameters['lat'],
                  lonParam: state.uri.queryParameters['lon'],
                  labelParam: state.uri.queryParameters['label'],
                  zoomParam: state.uri.queryParameters['zoom'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plan',
                name: 'plan',
                builder: (_, __) => const PlanScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        parentNavigatorKey: rootNavigatorKey,
        builder: (ctx, _) => BlocProvider(
          create: (ctx) => SearchBloc(ctx.read<IGeocodingRepository>()),
          child: const SearchScreen(),
        ),
      ),

      GoRoute(
        path: '/saved-places',
        name: 'savedPlaces',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, __) => const SavedPlacesScreen(),
      ),
      GoRoute(
        path: '/saved-routes',
        name: 'savedRoutes',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, __) => const SavedRoutesScreen(),
      ),
      GoRoute(
        path: '/saved-routes/import-preview',
        name: 'importPreview',
        parentNavigatorKey: rootNavigatorKey,
        builder: (ctx, state) {
          final routeJson = state.extra as String?;
          final source = state.uri.queryParameters['from'] ?? 'gpx';
          return ImportPreviewScreen(
            routeJson: routeJson != null && routeJson.isNotEmpty
                ? routeJson
                : null,
            source: source,
          );
        },
      ),
      GoRoute(
        path: '/devices',
        name: 'devices',
        builder: (_, _) => const DeviceManagementScreen(),
      ),
      GoRoute(
        path: '/add-device',
        name: 'addDevice',
        builder: (_, _) => const AddDeviceScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/offline-maps',
        name: 'offlineMaps',
        builder: (_, _) => const OfflineMapsScreen(),
      ),
      GoRoute(
        path: '/licenses',
        name: 'licenses',
        builder: (_, _) => const LicensesScreen(),
      ),
      GoRoute(
        path: '/navigate',
        name: 'navigate',
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/plan-route',
        name: 'planRoute',
        builder: (ctx, state) {
          final g = GeocodingResult.fromPathParams(state.uri.queryParameters);
          if (g == null) return _RedirectToShell();
          return PlanRouteScreen(destination: g);
        },
      ),
      GoRoute(
        path: '/plan-route/saved',
        name: 'savedRoutePreview',
        parentNavigatorKey: rootNavigatorKey,
        builder: (ctx, state) {
          final savedRoute = state.extra as SavedRoute;
          return PlanRouteScreen(savedRoute: savedRoute);
        },
      ),
      GoRoute(
        path: '/trips',
        name: 'trips',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, __) => const TripHistoryScreen(),
      ),
      GoRoute(
        path: '/trip-detail',
        name: 'tripDetail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (ctx, state) {
          final trip = state.extra as Trip;
          return TripDetailScreen(trip: trip);
        },
      ),
      GoRoute(
        path: '/route-finish',
        name: 'routeFinish',
        parentNavigatorKey: rootNavigatorKey,
        builder: (ctx, state) {
          final payload = state.extra as RouteFinishPayload;
          return RouteFinishScreen(payload: payload);
        },
      ),
      GoRoute(
        path: '/device-comm-debug',
        name: 'deviceCommDebug',
        parentNavigatorKey: rootNavigatorKey,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>;
          final routePoints = (extra['routePoints'] as List).cast<LatLng>();
          return DeviceCommDebugScreen(
            routePoints: routePoints,
            distanceM: extra['distanceM'] as double?,
            durationS: extra['durationS'] as double?,
            polyline: extra['polyline'] as String? ?? '',
          );
        },
      ),
    ],
    errorBuilder: (_, __) => HomeScreen(),
  );
}

/// One-time redirect to shell (Explore). Used when a route has invalid/missing data.
class _RedirectToShell extends StatefulWidget {
  @override
  State<_RedirectToShell> createState() => _RedirectToShellState();
}

class _RedirectToShellState extends State<_RedirectToShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
