import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';
import 'package:nav_e/core/domain/repositories/saved_places_repository.dart';
import 'package:nav_e/features/device_management/add_device_screen.dart';
import 'package:nav_e/features/device_management/device_management_screen.dart';
import 'package:nav_e/features/device_comm/presentation/screens/device_comm_debug_screen.dart';

import 'package:nav_e/features/home/home_screen.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/features/plan_route/plan_route_screen.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/features/saved_places/saved_places_screen.dart';
import 'package:nav_e/features/search/bloc/search_bloc.dart';
import 'package:nav_e/features/search/search_screen.dart';
import 'package:nav_e/features/settings/settings_screen.dart';
import 'package:nav_e/features/settings/licenses_screen.dart';
import 'package:nav_e/features/offline_maps/presentation/offline_maps_screen.dart';

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
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (ctx, state) => HomeScreen(
          placeId: state.uri.queryParameters['placeId'],
          latParam: state.uri.queryParameters['lat'],
          lonParam: state.uri.queryParameters['lon'],
          labelParam: state.uri.queryParameters['label'],
          zoomParam: state.uri.queryParameters['zoom'],
        ),
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
        builder: (ctx, _) => BlocProvider(
          create: (c) =>
              SavedPlacesCubit(c.read<ISavedPlacesRepository>())..loadPlaces(),
          child: const SavedPlacesScreen(),
        ),
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
          final params = state.uri.queryParameters;
          final g = GeocodingResult.fromPathParams(params);
          if (g == null) return const HomeScreen();
          return PlanRouteScreen(destination: g);
        },
      ),
      GoRoute(
        path: '/device-comm-debug',
        name: 'deviceCommDebug',
        parentNavigatorKey: rootNavigatorKey,
        builder: (ctx, state) {
          // Route data passed via extra
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) return const HomeScreen();
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
    errorBuilder: (_, _) => const HomeScreen(),
  );
}
