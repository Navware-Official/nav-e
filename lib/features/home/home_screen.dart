import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/core/bloc/map_bloc.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/features/home/widgets/bottom_navigation_bar.dart';
import 'package:nav_e/features/home/widgets/location_preview_widget.dart';
import 'package:nav_e/features/home/widgets/map_section.dart';
import 'package:nav_e/features/home/widgets/recenter_fab.dart';
import 'package:nav_e/features/home/widgets/rotate_north_fab.dart';
import 'package:nav_e/features/home/widgets/search_overlay_widget.dart';
import 'package:nav_e/widgets/side_menu_drawer.dart';
import 'package:flutter_map/flutter_map.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  bool showRoutePreview = false;
  dynamic selectedRoute;

  @override
  void initState() {
    super.initState();
    context.read<LocationBloc>().add(StartLocationTracking());
  }

  void onSearchResultSelected(dynamic result) {
    final marker = Marker(
      point: result.position,
      width: 45,
      height: 45,
      child: const Icon(Icons.place, color: Color.fromARGB(255, 202, 11, 11), size: 52),
    );

    setState(() {
      selectedRoute = result;
      showRoutePreview = true;
      _markers.clear();
      _markers.add(marker);
    });

    context.read<MapBloc>().add(ToggleFollowUser(false));

    _mapController.move(result.position, 16.0);
  }

  void openLocationPreview() {
    setState(() {
      showRoutePreview = true;
    });
    context.read<LocationBloc>().add(StopLocationTracking());
  }

  void closeLocationPreview() {
    setState(() {
      showRoutePreview = false;
    });
    _markers.clear();
    context.read<LocationBloc>().add(StartLocationTracking());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
        BlocListener<LocationBloc, LocationState>(
          listenWhen: (prev, curr) => curr.position != prev.position,
          listener: (context, state) {
            final followUser = context.read<MapBloc>().state.followUser;
            if (followUser && state.position != null) {
              _mapController.move(state.position!, 16.0);
              if (state.heading != null && state.heading!.isFinite) {
                _mapController.rotate(state.heading!);
              }
            }
          },
          child: Stack(
            children: [
              MapSection(
                mapController: _mapController,
                extraMarkers: _markers,
              ),
              SearchOverlayWidget(onResultSelected: onSearchResultSelected),
              RecenterFAB(mapController: _mapController),
              RotateNorthFAB(mapController: _mapController),
              if (showRoutePreview && selectedRoute != null)
                LocationPreviewWidget(
                  route: selectedRoute,
                  onClose: closeLocationPreview,
                ),
                // TODO: Remove map marker
            ],
          ),
        ),
        
      drawer: SideMenuDrawerWidget(),
      bottomNavigationBar: BottomNavigationBarWidget(),
    );
  }

}
