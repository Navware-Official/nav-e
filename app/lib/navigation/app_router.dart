import 'package:go_router/go_router.dart';
import '../features/home/views/home_screen.dart';
import '../features/settings/views/settings_screen.dart';
import '../features/start_route/views/start_route_screen.dart';
import 'routes.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.startNav,
      name: 'start_navigation',
      builder: (context, state) => const StartRouteScreen()
    ),
  ],
);
