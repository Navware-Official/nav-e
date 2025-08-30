import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/features/home/widgets/bottom_navigation_bar.dart'
    show BottomNavigationBarWidget;
import 'package:nav_e/features/home/widgets/location_preview_widget.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/map_section.dart';
import 'package:nav_e/features/home/widgets/recenter_fab.dart';
import 'package:nav_e/features/home/widgets/rotate_north_fab.dart';
import 'package:nav_e/features/home/widgets/search_overlay_widget.dart'
    show SearchOverlayWidget;
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/widgets/side_menu_drawer.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];

  bool showRoutePreview = false;
  dynamic selectedRoute;

  void onSearchResultSelected(dynamic result) {
    final marker = Marker(
      point: result.position,
      width: 45,
      height: 45,
      child: const Icon(Icons.place, color: Colors.red, size: 52),
    );

    setState(() {
      selectedRoute = result;
      showRoutePreview = true;
      _markers
        ..clear()
        ..add(marker);
    });

    context.read<MapBloc>().add(ToggleFollowUser(false));
    _mapController.move(result.position, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<LocationBloc, LocationState>(
        listenWhen: (prev, curr) =>
            curr.position != prev.position || curr.heading != prev.heading,
        listener: (context, state) {
          final followUser = context.read<MapBloc>().state.followUser;
          if (followUser && state.position != null) {
            _mapController.move(state.position!, 16.0);
            final heading = state.heading;
            if (heading != null && heading.isFinite) {
              _mapController.rotate(heading);
            }
          }
        },
        child: Stack(
          children: [
            MapSection(mapController: _mapController, extraMarkers: _markers),
            SearchOverlayWidget(onResultSelected: onSearchResultSelected),
            RecenterFAB(mapController: _mapController),
            RotateNorthFAB(mapController: _mapController),
            if (showRoutePreview && selectedRoute != null)
              LocationPreviewWidget(
                route: selectedRoute,
                onClose: () => setState(() => showRoutePreview = false),
              ),
          ],
        ),
      ),
      drawer: const SideMenuDrawerWidget(),
      bottomNavigationBar: const BottomNavigationBarWidget(),
    );
  }
}
