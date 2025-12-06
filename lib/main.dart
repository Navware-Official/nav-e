import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nav_e/app/app_router.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/core/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:nav_e/core/data/local/database_helper.dart';

import 'package:nav_e/core/domain/repositories/saved_places_repository.dart';
import 'package:nav_e/core/domain/repositories/device_repository.dart';
import 'package:nav_e/features/device_management/data/device_repository_impl.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/saved_places/data/saved_places_repository_impl.dart';
import 'package:nav_e/features/search/data/geocoding_repository_frb_typed_impl.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';

import 'package:nav_e/core/data/remote/map_source_repository_impl.dart';
import 'package:nav_e/core/domain/repositories/map_source_repository.dart';

import 'package:nav_e/core/theme/app_theme.dart';
import 'package:nav_e/core/theme/theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final geocodingRepo = GeocodingRepositoryFrbTypedImpl();

  final mapSourceRepo = MapSourceRepositoryImpl();
  final db = await DatabaseHelper.instance.database;
  final savedPlacesRepo = SavedPlacesRepositoryImpl(db);
  final deviceRepo = DeviceRepositoryImpl(db);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IGeocodingRepository>.value(value: geocodingRepo),
        RepositoryProvider<ISavedPlacesRepository>.value(
          value: savedPlacesRepo,
        ),
        RepositoryProvider<IMapSourceRepository>.value(value: mapSourceRepo),
        RepositoryProvider<IDeviceRepository>.value(value: deviceRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(
            create: (_) => LocationBloc()..add(StartLocationTracking()),
          ),
          BlocProvider(
            create: (ctx) =>
                MapBloc(ctx.read<IMapSourceRepository>())
                  ..add(MapInitialized()),
          ),
          BlocProvider(
            create: (ctx) => DevicesBloc(ctx.read<IDeviceRepository>()),
          ),
          BlocProvider(
            create: (_) => BluetoothBloc(DatabaseHelper.instance),
          ),
        ],
        child: BlocBuilder<ThemeCubit, AppThemeMode>(
          builder: (context, mode) {
            final router = buildRouter(
              refreshListenable: GoRouterRefreshStream(
                context.read<ThemeCubit>().stream,
              ),
            );

            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: router,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: context.read<ThemeCubit>().toFlutterMode(mode),
            );
          },
        ),
      ),
    ),
  );
}
