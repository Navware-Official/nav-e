import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/app/app_router_delegate.dart';
import 'package:nav_e/app/route_parser.dart';
import 'package:nav_e/bloc/app_state_bloc.dart';
import 'package:nav_e/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:nav_e/bloc/devices/devices_bloc.dart';
import 'package:nav_e/bloc/location_bloc.dart';
import 'package:nav_e/bloc/map_bloc.dart';
import 'package:nav_e/core/theme/app_theme.dart';
import 'package:nav_e/screens/search/bloc/search_bloc.dart';
import 'package:nav_e/services/geocoding_service.dart';
import 'package:nav_e/utils/database_helper.dart'; // <-- Import your theme

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
        BlocProvider<BluetoothBloc>(
          create: (_) => BluetoothBloc(DatabaseHelper()),
        ),
        BlocProvider<DevicesBloc>(
          create: (_) => DevicesBloc(DatabaseHelper()),
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
