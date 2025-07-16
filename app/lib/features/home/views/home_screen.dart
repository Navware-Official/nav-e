import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/search_bar_widget.dart';
import 'package:nav_e/widgets/draggable_fab_widget.dart';
import 'package:nav_e/widgets/map_widget.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnUser();
    });
  }

  Future<void> _centerOnUser() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    final pos = await Geolocator.getCurrentPosition();
    final latlng = LatLng(pos.latitude, pos.longitude);

    _mapController.move(latlng, 5);
    _mapController.rotate(0.0);
  }

  Future<void> _rotateNorth() async {
    final pos = await Geolocator.getCurrentPosition();
    final latlng = LatLng(pos.latitude, pos.longitude);
    _mapController.rotate(0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(mapController: _mapController),
          const Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: SearchBarWidget(),
          ),
          DraggableFAB(
            onPressed: _centerOnUser,
            icon: Icons.location_searching_sharp,
            tooltip: 'Center Map Position',
          ),
          DraggableFAB(
            onPressed: _rotateNorth,
            icon: Icons.explore,
            tooltip: 'Rotate map to North',
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        height: 60,
        color: Colors.deepOrange,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings, size: 30),
              color: Colors.white,
              onPressed: () => context.goNamed('settings'),
            ),
            IconButton(
              tooltip: 'Start Navigation',
              icon: const Icon(Icons.assistant_navigation, size: 30),
              color: Colors.white,
              onPressed: () => context.goNamed('start_navigation'),
            ),
          ],
        ),
      ),
    );
  }
}
