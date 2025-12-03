import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';
import 'package:nav_e/core/domain/repositories/saved_places_repository.dart';
import 'package:nav_e/features/device_management/add_device_screen.dart';
import 'package:nav_e/features/device_management/device_management_screen.dart';

import 'package:nav_e/features/home/home_screen.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/features/saved_places/saved_places_screen.dart';
import 'package:nav_e/features/search/bloc/search_bloc.dart';
import 'package:nav_e/features/search/search_screen.dart';
import 'package:nav_e/features/settings/settings_screen.dart';

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
        path: '/navigate',
        name: 'navigate',
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (_, _) => const HomeScreen(),
  );
}
