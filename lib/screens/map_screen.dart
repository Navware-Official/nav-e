import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:nav_e/bloc/map_bloc.dart';


class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          return FlutterMap(
            options: MapOptions(
              initialCenter: state.center,
              initialZoom: state.zoom,
              onPositionChanged: (pos, _) {
                context.read<MapBloc>().add(
                      MapMoved(pos.center, pos.zoom),
                    );
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.yourapp',
              ),
            ],
          );
        },
      ),
    );
  }
}
