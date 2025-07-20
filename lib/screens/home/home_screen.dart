import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/bloc/location_bloc.dart';
import 'package:nav_e/bloc/map_bloc.dart';
import 'package:nav_e/screens/home/widgets/bottom_navigation_bar.dart';
import 'package:nav_e/screens/home/widgets/map_section.dart';
import 'package:nav_e/screens/home/widgets/recenter_fab.dart';
import 'package:nav_e/screens/home/widgets/rotate_north_fab.dart';
import 'package:nav_e/screens/home/widgets/search_overlay_widget.dart';
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

  @override
  void initState() {
    super.initState();
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
              const SearchOverlayWidget(),
              RecenterFAB(mapController: _mapController),
              RotateNorthFAB(mapController: _mapController),
            ],
          ),
      ),
      drawer: SideMenuDrawerWidget(),
      bottomNavigationBar: BottomNavigationBarWidget(),
    );
  }

}
