import 'dart:async';
import 'dart:convert';

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
import 'package:nav_e/features/settings/settings_subpages.dart';
import 'package:nav_e/features/settings/licenses_screen.dart';
import 'package:nav_e/features/settings/developer_settings_screen.dart';
import 'package:nav_e/features/offline_maps/presentation/offline_maps_screen.dart';
import 'package:nav_e/features/nav/ui/active_nav_screen.dart';
import 'package:nav_e/features/nav/ui/route_finish_screen.dart';
import 'package:nav_e/core/domain/entities/trip.dart';
import 'package:nav_e/features/trip_history/trip_history_screen.dart';
import 'package:nav_e/features/trip_history/trip_detail_screen.dart';
import 'package:nav_e/features/log/log_screen.dart';
import 'package:nav_e/features/plan/plan_screen.dart';
import 'package:nav_e/features/profile/profile_screen.dart';
import 'package:nav_e/features/profile/navware_auth_screen.dart';
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
      // Legacy path redirects — keep old paths working.
      if (state.uri.path == '/home') {
        final qp = state.uri.queryParameters;
        if (qp.isEmpty) return '/';
        return Uri(path: '/', queryParameters: qp).toString();
      }
      if (state.uri.path == '/plan') return '/routes';
      if (state.uri.path == '/profile') return '/more';

      if (state.uri.path == '/plan-route') {
        final g = GeocodingResult.fromPathParams(state.uri.queryParameters);
        if (g == null) {
          return '/';
        }
      }
      if (state.uri.path == '/plan-route/saved' && state.extra == null) {
        return '/';
      }
      if (state.uri.path == '/trip-detail' && state.extra == null) return '/';
      if (state.uri.path == '/route-finish' && state.extra == null) return '/';
      if (state.uri.path == '/device-comm-debug' && state.extra == null) {
        return '/';
      }
      if (state.uri.path == '/nav/active' && state.extra == null) return '/';
      if (state.error != null) return '/';
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Branch 0 — Map (primary)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'map',
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
          // Branch 1 — Routes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/routes',
                name: 'routes',
                builder: (_, state) => const PlanScreen(),
              ),
            ],
          ),
          // Branch 2 — Log
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/log',
                name: 'log',
                builder: (_, state) => LogScreen(
                  initialSegment:
                      state.uri.queryParameters['segment'] ?? 'trips',
                ),
              ),
            ],
          ),
          // Branch 3 — More
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                name: 'more',
                builder: (_, state) => const ProfileScreen(),
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
        builder: (_, state) => const SavedPlacesScreen(),
      ),
      GoRoute(
        path: '/saved-routes',
        name: 'savedRoutes',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) => const SavedRoutesScreen(),
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
        builder: (_, state) => const DeviceManagementScreen(),
      ),
      GoRoute(
        path: '/add-device',
        name: 'addDevice',
        builder: (_, state) => const AddDeviceScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/appearance',
        name: 'settingsAppearance',
        builder: (_, _) => const AppearanceSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/navigation',
        name: 'settingsNavigation',
        builder: (_, _) => const NavigationPrefsScreen(),
      ),
      GoRoute(
        path: '/settings/services',
        name: 'settingsServices',
        builder: (_, _) => const ServicesSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/data',
        name: 'settingsData',
        builder: (_, _) => const TripDataSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        name: 'settingsAbout',
        builder: (_, _) => const AboutSettingsScreen(),
      ),
      GoRoute(
        path: '/offline-maps',
        name: 'offlineMaps',
        builder: (_, state) => const OfflineMapsScreen(),
      ),
      GoRoute(
        path: '/licenses',
        name: 'licenses',
        builder: (_, state) => const LicensesScreen(),
      ),
      GoRoute(
        path: '/developer-settings',
        name: 'developerSettings',
        builder: (_, state) => const DeveloperSettingsScreen(),
      ),
      GoRoute(
        path: '/profile/navware-auth',
        name: 'navwareAuth',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const NavwareAuthScreen(),
      ),
      GoRoute(
        path: '/navigate',
        name: 'navigate',
        builder: (_, state) => const SettingsScreen(),
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
        builder: (_, state) => const TripHistoryScreen(),
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
        path: '/nav/active',
        name: 'activeNav',
        parentNavigatorKey: rootNavigatorKey,
        builder: (ctx, state) {
          final session = state.extra! as Map<String, dynamic>;
          return _ActiveNavFromSession(session: session);
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
    errorBuilder: (_, state) => HomeScreen(),
  );
}

/// Builds [ActiveNavScreen] from a restored session map (from [getActiveSession]).
class _ActiveNavFromSession extends StatelessWidget {
  const _ActiveNavFromSession({required this.session});

  final Map<String, dynamic> session;

  static List<LatLng> _parsePolyline(String? polylineJson) {
    if (polylineJson == null || polylineJson.isEmpty) return [];
    try {
      final coords = jsonDecode(polylineJson) as List<dynamic>;
      return coords.map((e) {
        final list = e as List<dynamic>;
        return LatLng((list[0] as num).toDouble(), (list[1] as num).toDouble());
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = session['id'] as String? ?? '';
    final routeMap = session['route'] as Map<String, dynamic>?;
    final polylineJson = routeMap?['polyline_json'] as String?;
    var routePoints = _parsePolyline(polylineJson);
    final waypoints = routeMap?['waypoints'] as List<dynamic>?;
    if (routePoints.isEmpty && waypoints != null && waypoints.length >= 2) {
      final first = waypoints.first as Map<String, dynamic>;
      final last = waypoints.last as Map<String, dynamic>;
      routePoints = [
        LatLng(
          (first['latitude'] as num).toDouble(),
          (first['longitude'] as num).toDouble(),
        ),
        LatLng(
          (last['latitude'] as num).toDouble(),
          (last['longitude'] as num).toDouble(),
        ),
      ];
    }
    final distanceM = (routeMap?['distance_meters'] as num?)?.toDouble();
    final durationS = (routeMap?['duration_seconds'] as num?)?.toDouble();
    final destinationLabel = waypoints != null && waypoints.isNotEmpty
        ? (waypoints.last as Map<String, dynamic>)['name'] as String?
        : null;

    return ActiveNavScreen(
      routeId: sessionId,
      routePoints: routePoints,
      distanceM: distanceM,
      durationS: durationS?.toDouble(),
      destinationLabel: destinationLabel,
      sessionId: sessionId,
    );
  }
}

/// One-time redirect to shell (Map). Used when a route has invalid/missing data.
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
