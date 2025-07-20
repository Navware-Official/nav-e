import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/theme/app_theme.dart';

class UserLocationMarker extends Marker {
  UserLocationMarker({required LatLng? position})
      : super(
          point: position ?? LatLng(0, 0),
          width: 45,
          height: 45,
          child: Container(
            decoration: AppTheme.userLocationMarkerDecoration,
            child: const Icon(
              Icons.navigation,
              size: 30,
            ),
          ),
        );
}