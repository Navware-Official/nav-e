import 'package:flutter/material.dart';

enum AppRoute { home, settings }

class RouteParser extends RouteInformationParser<AppRoute> {
  const RouteParser();

  @override
  Future<AppRoute> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.uri as String);
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'settings') {
      return AppRoute.settings;
    }
    return AppRoute.home;
  }

  
  @override
  RouteInformation? restoreRouteInformation(AppRoute configuration) {
    switch (configuration) {
      case AppRoute.settings:
        return RouteInformation(uri: Uri.parse('/settings'));
      case AppRoute.home:
        return RouteInformation(uri: Uri.parse('/'));
    }
  }
  
}