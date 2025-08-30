import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:nav_e/app/app_router.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/core/data/remote/geocoding_api_client.dart';
import 'package:nav_e/core/domain/repositories/geocoding_respository.dart';
import 'package:nav_e/features/search/data/geocoding_repository_impl.dart';
import 'package:nav_e/core/theme/app_theme.dart';
import 'package:nav_e/core/theme/theme_cubit.dart';

void main() {
  final geocodingRepo = GeocodingRepositoryImpl(
    GeocodingApiClient(http.Client()),
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IGeocodingRepository>.value(value: geocodingRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(
            create: (_) => LocationBloc()..add(StartLocationTracking()),
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
