import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/app/app_nav.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/core/domain/extensions/geocoding_to_saved.dart';
import 'package:nav_e/features/home/utils/route_params_handler.dart';
import 'package:nav_e/features/home/widgets/bottom_search_bar_widget.dart';
import 'package:nav_e/features/location_preview/cubit/preview_cubit.dart';
import 'package:nav_e/features/location_preview/location_preview_widget.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';
import 'package:nav_e/features/map_layers/presentation/utils/map_helpers.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/map_controls_fab.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/map_section.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/recenter_fab.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/rotate_north_fab.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/features/saved_places/utils/saved_places_utils.dart';

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
  final _routeHandler = RouteParamsHandler();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeHandler.initialize(context);
  }

  @override
  void dispose() {
    _routeHandler.removeListener(context);
    _routeHandler.dispose();
    super.dispose();
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
            listener: (context, s) {
              _routeHandler.setMapReady(s.isReady);
            },
          ),
          BlocListener<LocationBloc, LocationState>(
            listenWhen: (p, c) =>
                c.position != p.position || c.heading != p.heading,
            listener: (context, s) {
              // Camera movement is now handled by MapWidget based on followUser state
              // No need to manually move controller here
            },
          ),
          BlocListener<PreviewCubit, PreviewState>(
            listenWhen: (a, b) => a != b,
            listener: (context, state) {
              if (state is! LocationPreviewShowing) return;

              final mapState = context.read<MapBloc>().state;

              focusMapOnPreview(context, state, mapState, desiredZoom: 14);

              RouteParamsHandler.clearPreviewParams(context);
            },
          ),
        ],
        child: BlocBuilder<PreviewCubit, PreviewState>(
          buildWhen: (a, b) => a != b,
          builder: (context, state) {
            final markers = markersForPreview(state);
            return Stack(
              children: [
                MapSection(extraMarkers: markers),

                const RecenterFAB(),
                const RotateNorthFAB(),
                const MapControlsFAB(),

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
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await context.read<SavedPlacesCubit>().addPlace(
                          r.toSavedPlace(),
                        );
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Location saved')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to save: $e')),
                          );
                        }
                      }
                    },
                  ),

                BottomSearchBarWidget(
                  onResultSelected: (r) {
                    FocusScope.of(context).unfocus();
                    AppNav.homeWithCoords(
                      lat: r.lat,
                      lon: r.lon,
                      label: r.displayName,
                      placeId: r.id,
                      zoom: 14,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
