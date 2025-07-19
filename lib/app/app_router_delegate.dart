import 'package:flutter/material.dart';
import 'package:nav_e/bloc/app_state_bloc.dart';
import 'package:nav_e/screens/home_screen.dart';
import 'package:nav_e/screens/settings_screen.dart';
import 'package:nav_e/screens/active_route_screen.dart';

class AppRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  final AppStateBloc bloc;
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  AppRouterDelegate(this.bloc) {
    bloc.stream.listen((_) => notifyListeners());
  }

  @override
  Widget build(BuildContext context) {
    final state = bloc.state;

    final pages = <Page>[
      const MaterialPage(child: HomeScreen()),
    ];

    switch (state.stage) {
      case NavigationStage.settings:
        pages.add(const MaterialPage(child: SettingsScreen()));
        break;
      case NavigationStage.previewing:
        pages.add(MaterialPage(
          child: Container(color: Colors.yellow, child: const Center(child: Text("Preview Page"))),
        ));
        break;
      case NavigationStage.navigating:
        pages.add(const MaterialPage(child: ActiveRouteScreen()));
        break;
      default:
        break;
    }

    return Navigator(
      key: navigatorKey,
      pages: pages
    );
  }

  @override
  Future<void> setNewRoutePath(configuration) async {}
}
