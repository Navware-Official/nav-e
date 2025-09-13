import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';

import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/core/domain/extensions/geocoding_to_saved.dart';
import 'package:nav_e/core/domain/extensions/query_params.dart';
import 'package:nav_e/features/location_preview/cubit/preview_cubit.dart';

import 'package:nav_e/features/home/widgets/bottom_navigation_bar.dart'
    show BottomNavigationBarWidget;
import 'package:nav_e/features/location_preview/location_preview_widget.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/map_controls_fab.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/recenter_fab.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/rotate_north_fab.dart';
import 'package:nav_e/features/home/widgets/search_overlay_widget.dart'
    show SearchOverlayWidget;
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';
import 'package:nav_e/features/map_layers/presentation/utils/map_helpers.dart';

import 'package:nav_e/features/map_layers/presentation/widgets/map_section.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/saved_places/utils/saved_places_utils.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/widgets/side_menu_drawer.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    this.placeId,
    this.latParam,
    this.lonParam,
    this.labelParam,
    this.zoomParam,
  });

  final String? placeId;
  final String? latParam;
  final String? lonParam;
  final String? labelParam;
  final String? zoomParam;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  // Hanler for route changes
  VoidCallback? _routerListener;
  String? _lastUriString;
  String? _lastHandledRouteKey;
  bool _handlingRoute = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uri = GoRouterState.of(context).uri;
      _lastUriString = uri.toString();
      _handleRouteParams(uri);
    });

    final router = GoRouter.of(context);
    _routerListener ??= () {
      final uri = GoRouterState.of(context).uri;
      final s = uri.toString();
      if (_lastUriString == s) return;
      _lastUriString = s;
      _handleRouteParams(uri);
    };
    router.routerDelegate.addListener(_routerListener!);
  }

  Future<void> _handleRouteParams(Uri uri) async {
    if (_handlingRoute) return;

    final qp = uri.queryParameters;
    final lat = double.tryParse(qp['lat'] ?? '');
    final lon = double.tryParse(qp['lon'] ?? '');
    final label = qp['label'];

    if (lat == null || lon == null || label == null) {
      debugPrint('[HomeView] Missing lat/lon/label. Skip.');
      return;
    }

    final key =
        '${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}|$label|${qp['placeId'] ?? ''}';
    if (_lastHandledRouteKey == key) return;

    _handlingRoute = true;
    try {
      while (mounted && !_mapReady) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
      if (!mounted) return;

      _lastHandledRouteKey = key;
      context.read<PreviewCubit>().showCoords(
        lat: lat,
        lon: lon,
        label: label,
        placeId: qp['placeId'],
      );
    } finally {
      _handlingRoute = false;
    }
  }

  void _clearPreviewParams(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.goNamed('home', queryParameters: const {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    debugPrint('[HomeView] build uri = ${state.uri}');

    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<MapBloc, MapState>(
            listenWhen: (p, c) => p.isReady != c.isReady,
            listener: (_, s) {
              _mapReady = s.isReady;
              if (_mapReady) {
                setZoomIfProvided(_mapController, widget.zoomParam, _mapReady);
              }
            },
          ),
          BlocListener<LocationBloc, LocationState>(
            listenWhen: (p, c) =>
                c.position != p.position || c.heading != p.heading,
            listener: (context, s) {
              final follow = context.read<MapBloc>().state.followUser;
              if (_mapReady && follow && s.position != null) {
                _mapController.move(s.position!, 16.0);
                final h = s.heading;
                if (h != null && h.isFinite) _mapController.rotate(h);
              }
            },
          ),
          BlocListener<PreviewCubit, PreviewState>(
            listenWhen: (a, b) => a != b,
            listener: (context, state) {
              if (state is! LocationPreviewShowing) return;

              context.read<MapBloc>().add(ToggleFollowUser(false));

              WidgetsBinding.instance.addPostFrameCallback((_) {
                setZoomIfProvided(_mapController, widget.zoomParam, _mapReady);
                focusMapOnPreview(context, _mapController, state);
              });

              _clearPreviewParams(context);
            },
          ),
        ],
        child: BlocBuilder<PreviewCubit, PreviewState>(
          buildWhen: (a, b) => a != b,
          builder: (context, state) {
            final markers = markersForPreview(state);
            return Stack(
              children: [
                MapSection(
                  mapController: _mapController,
                  extraMarkers: markers,
                ),

                SearchOverlayWidget(
                  onResultSelected: (r) {
                    context.goHomeWithCoords(
                      lat: r.lat,
                      lon: r.lon,
                      label: r.displayName,
                      placeId: r.id,
                    );
                  },
                ),

                RecenterFAB(mapController: _mapController),
                RotateNorthFAB(mapController: _mapController),
                MapControlsFAB(),

                if (state is LocationPreviewShowing)
                  LocationPreviewWidget(
                    route: state.result,
                    onClose: () {
                      context.read<PreviewCubit>().hide();
                      context.read<MapBloc>().add(ToggleFollowUser(true));
                    },
                    onSave: () async {
                      final r = state.result;
                      if (isAlreadySaved(context, r)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Already saved')),
                        );
                        return;
                      }
                      try {
                        await context.read<SavedPlacesCubit>().addPlace(
                          r.toSavedPlace(),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location saved')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save: $e')),
                        );
                      }
                    },
                  ),
              ],
            );
          },
        ),
      ),
      drawer: const SideMenuDrawerWidget(),
      bottomNavigationBar: const BottomNavigationBarWidget(),
    );
  }
}
