import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/domain/repositories/saved_places_repository.dart';

import 'package:nav_e/features/home/home_screen.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/features/saved_places/saved_place_detail_screen.dart';
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

GoRouter buildRouter({Listenable? refreshListenable}) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(path: '/', name: 'home', builder: (_, _) => const HomeScreen()),

      GoRoute(
        path: '/search',
        name: 'search',
        builder: (ctx, _) => BlocProvider.value(
          value: ctx.read<SearchBloc>(),
          child: const SearchScreen(),
        ),
      ),

      GoRoute(
        path: '/saved-places',
        name: 'savedPlaces',
        builder: (ctx, _) => BlocProvider(
          create: (c) =>
              SavedPlacesCubit(c.read<ISavedPlacesRepository>())..loadPlaces(),
          child: const SavedPlacesScreen(),
        ),
      ),

      GoRoute(
        path: '/saved-places/:id',
        name: 'savedPlaceDetail',
        builder: (_, state) =>
            SavedPlaceDetailScreen(id: state.pathParameters['id']!),
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
