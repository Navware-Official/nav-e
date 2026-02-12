import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nav_e/app/app_router.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/core/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:nav_e/features/device_comm/device_comm_bloc.dart';

import 'package:nav_e/core/domain/repositories/saved_places_repository.dart';
import 'package:nav_e/core/domain/repositories/device_repository.dart';
import 'package:nav_e/features/device_management/data/device_repository_rust.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/saved_places/data/saved_places_repository_rust.dart';
import 'package:nav_e/features/search/data/geocoding_repository_frb_typed_impl.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';

import 'package:nav_e/core/data/remote/map_source_repository_impl.dart';
import 'package:nav_e/core/domain/repositories/map_source_repository.dart';
import 'package:nav_e/core/data/remote/composite_map_source_repository.dart';
import 'package:nav_e/core/domain/repositories/offline_regions_repository.dart';
import 'package:nav_e/features/offline_maps/data/offline_map_style_resolver.dart';
import 'package:nav_e/features/offline_maps/data/offline_regions_repository_rust.dart';

import 'package:nav_e/core/theme/app_theme.dart';
import 'package:nav_e/core/theme/theme_cubit.dart';
import 'package:nav_e/bridge/frb_generated.dart';
import 'package:nav_e/bridge/lib.dart' as rust_api;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    debugPrint('[Bloc] ${bloc.runtimeType} event=$event');
    super.onEvent(bloc, event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    debugPrint('[Bloc] ${bloc.runtimeType} transition=$transition');
    super.onTransition(bloc, transition);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Bloc.observer = AppBlocObserver();

  // Run app immediately so Flutter draws the first frame and the native splash is dismissed.
  // Rust bridge and DB init run after the first frame to avoid blocking.
  runApp(const _AppLoader());
}

/// Shows loading until Rust/DB init completes, then the real app or an error screen.
class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  bool _initComplete = false;
  Object? _initError;

  Future<void> _doInit() async {
    debugPrint('[main] Initializing Rust bridge...');
    // forceSameCodegenVersion: false avoids "content hash different" when the loaded
    // native lib was built before the last codegen (e.g. hot restart). For a proper
    // fix: flutter clean && make codegen && make build-android && run (no hot reload).
    await RustBridge.init(forceSameCodegenVersion: false);
    debugPrint('[main] Rust bridge ready.');

    debugPrint('[main] Getting app documents directory...');
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(appDir.path, 'nav_e.db');
    debugPrint('[main] Initializing database at $dbPath...');
    await rust_api.initializeDatabase(dbPath: dbPath);
    debugPrint('[main] Database ready.');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _doInit();
      } catch (e, st) {
        debugPrint('[main] Init failed: $e');
        debugPrint('[main] $st');
        if (mounted) setState(() => _initError = e);
        return;
      }
      if (mounted) setState(() => _initComplete = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return _InitErrorScreen(_initError!);
    }
    if (!_initComplete) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return _buildMainApp();
  }

  Widget _buildMainApp() {
    final geocodingRepo = GeocodingRepositoryFrbTypedImpl();
    final mapSourceRepo = MapSourceRepositoryImpl();
    final savedPlacesRepo = SavedPlacesRepositoryRust();
    final deviceRepo = DeviceRepositoryRust();
    final offlineRegionsRepo = OfflineRegionsRepositoryRust();
    final compositeMapSourceRepo = CompositeMapSourceRepository(
      mapSourceRepo,
      offlineRegionsRepo,
    );
    final offlineMapStyleResolver = OfflineMapStyleResolver(offlineRegionsRepo);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IGeocodingRepository>.value(value: geocodingRepo),
        RepositoryProvider<ISavedPlacesRepository>.value(
          value: savedPlacesRepo,
        ),
        RepositoryProvider<IMapSourceRepository>.value(
          value: compositeMapSourceRepo,
        ),
        RepositoryProvider<IDeviceRepository>.value(value: deviceRepo),
        RepositoryProvider<IOfflineRegionsRepository>.value(
          value: offlineRegionsRepo,
        ),
        RepositoryProvider<OfflineMapStyleResolver>.value(
          value: offlineMapStyleResolver,
        ),
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
          BlocProvider(create: (_) => BluetoothBloc()),
          BlocProvider(create: (_) => DeviceCommBloc()),
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
    );
  }
}

class _InitErrorScreen extends StatelessWidget {
  const _InitErrorScreen(this.error);

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to start',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('$error', style: const TextStyle(fontFamily: 'monospace')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
