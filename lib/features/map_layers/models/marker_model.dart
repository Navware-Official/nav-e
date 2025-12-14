import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Marker model for the map (adapter-agnostic)
class MarkerModel {
  final String id;
  final LatLng position;
  final Widget icon;
  final double width;
  final double height;

  const MarkerModel({
    required this.id,
    required this.position,
    required this.icon,
    this.width = 45,
    this.height = 45,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkerModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          position == other.position;

  @override
  int get hashCode => id.hashCode ^ position.hashCode;
}
