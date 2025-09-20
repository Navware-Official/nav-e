import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/theme/components/decorations.dart';

class UserLocationMarker extends Marker {
  UserLocationMarker({required LatLng? position, double? heading})
      : super(
          point: position ?? LatLng(0, 0),
          width: 45,
          height: 45,
          child: Container(
            decoration: AppDecorations.userLocationMarker,
            child: Transform.rotate(
              angle: (heading ?? 0) * math.pi / 180,
              child: const Icon(
                Icons.navigation,
                size: 30,
              ),
            ),
          ),
        );
}