import 'package:flutter/material.dart';

class RouteParser extends RouteInformationParser<Object> {
  const RouteParser();

  @override
  Future<Object> parseRouteInformation(RouteInformation routeInformation) async {
    return Object();
  }

  @override
  RouteInformation? restoreRouteInformation(Object configuration) {
    return null;
  }
}
