import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nav_e/app/app_router.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/core/platform/route_import_channel.dart';
import 'package:nav_e/core/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:nav_e/core/device_comm/ble_device_comm_transport.dart';
import 'package:nav_e/core/device_comm/device_communication_service.dart';
import 'package:nav_e/core/device_comm/device_comm_transport.dart';
import 'package:nav_e/features/device_comm/device_comm_bloc.dart';

import 'package:nav_e/core/domain/repositories/saved_places_repository.dart';
import 'package:nav_e/core/domain/repositories/saved_routes_repository.dart';
import 'package:nav_e/core/domain/repositories/device_repository.dart';
import 'package:nav_e/core/domain/repositories/trip_repository.dart';
import 'package:nav_e/features/device_management/data/device_repository_rust.dart';
import 'package:nav_e/features/saved_routes/data/saved_routes_repository_rust.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/features/saved_places/data/saved_places_repository_rust.dart';
import 'package:nav_e/features/saved_routes/cubit/saved_routes_cubit.dart';
import 'package:nav_e/features/trip_history/cubit/trip_history_cubit.dart';
import 'package:nav_e/features/trip_history/data/trip_repository_rust.dart';
import 'package:nav_e/features/location_preview/cubit/preview_cubit.dart';
import 'package:nav_e/features/search/data/geocoding_repository_frb_typed_impl.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';

import 'package:nav_e/core/data/remote/map_source_repository_impl.dart';
import 'package:nav_e/core/domain/repositories/map_source_repository.dart';
import 'package:nav_e/core/data/remote/composite_map_source_repository.dart';
import 'package:nav_e/core/domain/repositories/offline_regions_repository.dart';
import 'package:nav_e/features/offline_maps/cubit/offline_maps_cubit.dart';
import 'package:nav_e/features/offline_maps/data/offline_map_style_resolver.dart';
import 'package:nav_e/features/offline_maps/data/offline_regions_repository_rust.dart';

import 'package:nav_e/core/theme/app_theme.dart';
import 'package:nav_e/core/theme/theme_cubit.dart';
import 'package:nav_e/bridge/frb_generated.dart';
import 'package:nav_e/bridge/lib.dart' as rust_api;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:go_router/go_router.dart';

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
    final savedRoutesRepo = SavedRoutesRepositoryRust();
    final tripRepo = TripRepositoryRust();
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
        RepositoryProvider<ISavedRoutesRepository>.value(
          value: savedRoutesRepo,
        ),
        RepositoryProvider<ITripRepository>.value(value: tripRepo),
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
          BlocProvider(
            create: (_) {
              final DeviceCommTransport transport = BleDeviceCommTransport();
              final service = DeviceCommunicationService(transport);
              return DeviceCommBloc(deviceCommService: service);
            },
          ),
          BlocProvider(
            create: (ctx) =>
                SavedPlacesCubit(ctx.read<ISavedPlacesRepository>())
                  ..loadPlaces(),
          ),
          BlocProvider(create: (_) => PreviewCubit()),
          BlocProvider(
            create: (ctx) => TripHistoryCubit(ctx.read<ITripRepository>()),
          ),
          BlocProvider(
            create: (ctx) =>
                SavedRoutesCubit(ctx.read<ISavedRoutesRepository>()),
          ),
          BlocProvider(
            create: (ctx) =>
                OfflineMapsCubit(ctx.read<IOfflineRegionsRepository>()),
          ),
        ],
        child: BlocBuilder<ThemeCubit, AppThemeMode>(
          builder: (context, mode) {
            final router = buildRouter(
              refreshListenable: GoRouterRefreshStream(
                context.read<ThemeCubit>().stream,
              ),
            );

            return _PendingImportWrapper(
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: router,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: context.read<ThemeCubit>().toFlutterMode(mode),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Runs once after first frame: if app was opened with a shared GPX URI, imports it and navigates to saved routes.
class _PendingImportWrapper extends StatefulWidget {
  const _PendingImportWrapper({required this.child});

  final Widget child;

  @override
  State<_PendingImportWrapper> createState() => _PendingImportWrapperState();
}

class _PendingImportWrapperState extends State<_PendingImportWrapper> {
  static bool _checked = false;

  @override
  void initState() {
    super.initState();
    if (_checked) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingImport());
  }

  Future<void> _checkPendingImport() async {
    if (_checked) return;
    _checked = true;
    final uri = await getPendingImportUri();
    if (uri == null || uri.isEmpty) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    try {
      final bytes = await readFileFromUri(uri);
      if (!ctx.mounted) return;
      final repo = ctx.read<ISavedRoutesRepository>();
      final routeJson = await repo.parseRouteFromGpxBytes(bytes);
      if (!ctx.mounted) return;
      ctx.goNamed('importPreview', extra: routeJson);
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _InitErrorScreen extends StatelessWidget {
  const _InitErrorScreen(this.error);

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
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
                Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to start',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
