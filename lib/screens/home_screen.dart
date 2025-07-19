import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/bloc/app_state_bloc.dart';
import 'package:nav_e/widgets/side_menu_drawer.dart';
import 'package:nav_e/widgets/search_bar_widget.dart';
import 'package:nav_e/widgets/draggable_fab_widget.dart';
import 'package:nav_e/widgets/map_widget.dart';

import 'package:nav_e/services/location_permission_handler.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'package:nav_e/bloc/map_bloc.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnUser();
    });
  }

  Future<void> _centerOnUser() async {
    bool hasPermission = await LocationPermissionHandler.checkAndRequestPermission(this);
    if (!hasPermission) return;

    final pos = await Geolocator.getCurrentPosition();
    final latlng = LatLng(pos.latitude, pos.longitude);

    // get the device heading and rotate the map to face the same direction
    final heading = pos.heading;
    _mapController.rotate(heading);

    context.read<MapBloc>().add(MapMoved(latlng, 16.0));
    
  }

  Future<void> _rotateNorth() async {
    bool hasPermission = await LocationPermissionHandler.checkAndRequestPermission(this);
    if (!hasPermission) return;

    _mapController.rotate(0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(mapController: _mapController, markers: _markers),
          const Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: SearchBarWidget(),
          ),
          DraggableFAB(
            identifier: 'center_map_on_user',
            onPressed: _centerOnUser,
            icon: Icons.location_searching_sharp,
            tooltip: 'Center Map Position',
          ),
          DraggableFAB(
            identifier: 'rotate_north',
            onPressed: _rotateNorth,
            icon: Icons.explore,
            tooltip: 'Rotate map to North',
            shape: const CircleBorder(),
          ),
        ],
      ),
      drawer: SideMenuDrawerWidget(),
      bottomNavigationBar: BottomAppBar(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.menu, size: 30),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            IconButton(
              tooltip: 'Start Navigation',
              icon: const Icon(Icons.assistant_navigation, size: 30),
              onPressed: () {
                context.read<AppStateBloc>().add(StartNavigation());
              },
            ),
          ],
        ),
      ),
    );
  }
}
