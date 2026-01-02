import 'package:latlong2/latlong.dart';

/// Lightweight polyline model used in bloc state (no widget types).
class PolylineModel {
  final String id;
  final List<LatLng> points;
  final int colorArgb;
  final double strokeWidth;

  const PolylineModel({
    required this.id,
    required this.points,
    this.colorArgb = 0xFF375AF9,
    this.strokeWidth = 4.0,
  });
}
