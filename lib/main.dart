import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/app/app_router_delegate.dart';
import 'package:nav_e/app/route_parser.dart';
import 'package:nav_e/core/bloc/app_state_bloc.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/core/bloc/map_bloc.dart';
import 'package:nav_e/core/theme/app_theme.dart';
import 'package:nav_e/features/search/bloc/search_bloc.dart';
import 'package:nav_e/core/services/geocoding_service.dart';

void main() {
  final appStateBloc = AppStateBloc();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AppStateBloc>(
          create: (_) => appStateBloc,
        ),
        BlocProvider<MapBloc>(
          create: (_) => MapBloc()..add(MapInitialized()),
        ),
        BlocProvider<LocationBloc>(
          create: (_) => LocationBloc(),
        ),
        BlocProvider<SearchBloc>(
          create: (_) => SearchBloc(GeocodingService()),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        // darkTheme: AppTheme.darkTheme,
        // themeMode: ThemeMode.system,  // Uncomment to use system theme again.
        routerDelegate: AppRouterDelegate(appStateBloc),
        routeInformationParser: const RouteParser(),
      ),
    ),
  );
}
