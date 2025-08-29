import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:nav_e/features/home/home_screen.dart';
import 'package:nav_e/features/saved_places/saved_placed_detail_screen.dart';
import 'package:nav_e/features/settings/settings_screen.dart';
import 'package:nav_e/features/navigate/navigation_screen.dart';
import 'package:nav_e/features/saved_places/saved_places_sreen.dart';

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

GoRouter buildRouter({Listenable? refreshListenable}) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(path: '/', name: 'home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/navigate',
        name: 'navigate',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/saved-places',
        name: 'savedPlaces',
        builder: (_, __) => const SavedPlacesScreen(),
      ),
      GoRoute(
        path: '/saved-places/:id',
        name: 'savedPlaceDetail',
        builder: (_, state) =>
            SavedPlaceDetailScreen(id: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (_, state) => const HomeScreen(),
  );
}
