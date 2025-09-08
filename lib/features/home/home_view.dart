import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';

import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/domain/extensions/query_params.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/features/location_preview/cubit/preview_cubit.dart';

import 'package:nav_e/features/home/widgets/bottom_navigation_bar.dart'
    show BottomNavigationBarWidget;
import 'package:nav_e/features/location_preview/location_preview_widget.dart';
import 'package:nav_e/features/home/widgets/recenter_fab.dart';
import 'package:nav_e/features/home/widgets/rotate_north_fab.dart';
import 'package:nav_e/features/home/widgets/search_overlay_widget.dart'
    show SearchOverlayWidget;
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';

import 'package:nav_e/features/map_layers/presentation/widgets/map_section.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
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
  final List<Marker> _markers = [];

  bool _mapReady = false;
  bool showRoutePreview = false;
  GeocodingResult? selectedRoute;

  String? _lastHandledKey;

  void _setPreview(GeocodingResult result) {
    selectedRoute = result;
    _applyPreviewIfAny();
  }

  void _applyPreviewIfAny() {
    if (!_mapReady || selectedRoute == null) return;

    final route = selectedRoute!;
    final marker = Marker(
      point: route.position,
      width: 45,
      height: 45,
      child: const Icon(
        Icons.place,
        color: Color.fromARGB(255, 54, 70, 244),
        size: 52,
      ),
    );

    setState(() {
      showRoutePreview = true;
      _markers
        ..clear()
        ..add(marker);
    });

    context.read<MapBloc>().add(ToggleFollowUser(false));
    _mapController.move(route.position, 16.0);
  }

  void _setZoomIfProvided() {
    final z = double.tryParse(widget.zoomParam ?? '');
    if (z == null || !_mapReady) return;
    _mapController.move(_mapController.camera.center, z);
  }

  void onSearchResultSelected(GeocodingResult result) => _setPreview(result);

  Future<void> _handleRouteParams() async {
    final router = GoRouter.of(context);
    final current = Uri.parse(
      router.routerDelegate.currentConfiguration.fullPath,
    );
    final qp = current.queryParameters;

    final lat = double.tryParse(qp['lat'] ?? '');
    final lon = double.tryParse(qp['lon'] ?? '');
    final label = qp['label'];

    if (lat == null || lon == null || label == null) return;

    final key = 'pt:${qp['lat']},${qp['lon']},${qp['label']},${qp['zoom']}';
    if (_lastHandledKey == key) return;
    _lastHandledKey = key;

    while (mounted && !_mapReady) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (!mounted) return;

    context.read<PreviewCubit>().showCoords(
      lat: lat,
      lon: lon,
      label: label,
      placeId: qp['placeId'],
    );
  }

  void _clearPreviewParams() {
    context.clearPreviewParams();
    context.read<MapBloc>().add(ToggleFollowUser(true));
    selectedRoute = null;
    setState(() {
      showRoutePreview = false;
      _markers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: MultiBlocListener(
          listeners: [
            BlocListener<MapBloc, MapState>(
              listenWhen: (prev, curr) => prev.isReady != curr.isReady,
              listener: (_, state) {
                _mapReady = state.isReady;
                if (_mapReady) _setZoomIfProvided();
              },
            ),

            // Follow-user camera updates
            BlocListener<LocationBloc, LocationState>(
              listenWhen: (prev, curr) =>
                  curr.position != prev.position ||
                  curr.heading != prev.heading,
              listener: (context, state) {
                final followUser = context.read<MapBloc>().state.followUser;
                if (_mapReady && followUser && state.position != null) {
                  _mapController.move(state.position!, 16.0);
                  final heading = state.heading;
                  if (heading != null && heading.isFinite) {
                    _mapController.rotate(heading);
                  }
                }
              },
            ),

            BlocListener<PreviewCubit, PreviewState>(
              listenWhen: (a, b) => a != b,
              listener: (context, state) {
                if (state is! PreviewShowing) return;
                final res = state.result;

                _setZoomIfProvided();
                _setPreview(res);

                _clearPreviewParams();
                context.read<PreviewCubit>().clear();
              },
            ),
          ],
          child: Stack(
            children: [
              MapSection(mapController: _mapController, extraMarkers: _markers),

              SearchOverlayWidget(
                onResultSelected: (res) {
                  _setPreview(res);
                },
              ),

              // Controls
              RecenterFAB(mapController: _mapController),
              RotateNorthFAB(mapController: _mapController),

              if (showRoutePreview)
                Positioned(
                  top: 12,
                  left: 12,
                  child: SafeArea(
                    child: Material(
                      color: AppColors.blueRibbonDark02,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            showRoutePreview = false;
                            selectedRoute = null;
                            _markers.clear();
                          });
                        },
                      ),
                    ),
                  ),
                ),

              if (showRoutePreview && selectedRoute != null)
                LocationPreviewWidget(
                  route: selectedRoute!,
                  onClose: () => setState(() => showRoutePreview = false),
                  onSave: () async {},
                ),
            ],
          ),
        ),

        drawer: const SideMenuDrawerWidget(),
        bottomNavigationBar: const BottomNavigationBarWidget(),
      )
      ..createElement().owner?.buildScope(
        () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _handleRouteParams();
              });
            }
            as Element,
      );
  }
}
