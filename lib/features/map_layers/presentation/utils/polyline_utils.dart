import 'package:latlong2/latlong.dart';

/// Utilities for working with polylines across different map adapters
class PolylineUtils {
  /// Calculate the bounding box for a list of coordinates
  static ({LatLng southwest, LatLng northeast}) calculateBounds(
    List<LatLng> coordinates,
  ) {
    if (coordinates.isEmpty) {
      throw ArgumentError('Cannot calculate bounds for empty coordinate list');
    }

    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;

    for (final coord in coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    return (
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Calculate the center point of a list of coordinates
  static LatLng calculateCenter(List<LatLng> coordinates) {
    if (coordinates.isEmpty) {
      throw ArgumentError('Cannot calculate center for empty coordinate list');
    }

    double sumLat = 0;
    double sumLng = 0;

    for (final coord in coordinates) {
      sumLat += coord.latitude;
      sumLng += coord.longitude;
    }

    return LatLng(sumLat / coordinates.length, sumLng / coordinates.length);
  }

  /// Simplify a polyline using the Ramer-Douglas-Peucker algorithm
  ///
  /// [coordinates] - The list of coordinates to simplify
  /// [tolerance] - The tolerance in degrees (smaller = more detail)
  static List<LatLng> simplify(List<LatLng> coordinates, double tolerance) {
    if (coordinates.length <= 2) return coordinates;

    // Find the point with the maximum distance from line segment
    double maxDistance = 0;
    int maxIndex = 0;
    final end = coordinates.length - 1;

    for (int i = 1; i < end; i++) {
      final distance = _perpendicularDistance(
        coordinates[i],
        coordinates.first,
        coordinates.last,
      );
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If max distance is greater than tolerance, recursively simplify
    if (maxDistance > tolerance) {
      final left = simplify(coordinates.sublist(0, maxIndex + 1), tolerance);
      final right = simplify(coordinates.sublist(maxIndex), tolerance);

      // Combine results, removing duplicate point at maxIndex
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      // Return just the endpoints
      return [coordinates.first, coordinates.last];
    }
  }

  /// Calculate perpendicular distance from a point to a line segment
  static double _perpendicularDistance(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    final x = point.longitude;
    final y = point.latitude;
    final x1 = lineStart.longitude;
    final y1 = lineStart.latitude;
    final x2 = lineEnd.longitude;
    final y2 = lineEnd.latitude;

    final dx = x2 - x1;
    final dy = y2 - y1;

    // Handle degenerate case where line segment is a point
    if (dx == 0 && dy == 0) {
      return _distance(point, lineStart);
    }

    final t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);

    if (t < 0) {
      return _distance(point, lineStart);
    } else if (t > 1) {
      return _distance(point, lineEnd);
    } else {
      final projX = x1 + t * dx;
      final projY = y1 + t * dy;
      return _distance(point, LatLng(projY, projX));
    }
  }

  /// Calculate simple Euclidean distance between two points
  /// (Good enough for short distances and simplification)
  static double _distance(LatLng p1, LatLng p2) {
    final dx = p2.longitude - p1.longitude;
    final dy = p2.latitude - p1.latitude;
    return (dx * dx + dy * dy); // Skip sqrt for comparison purposes
  }

  /// Decode a Google Polyline encoded string
  /// Useful for route data from various routing APIs
  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  /// Encode a list of coordinates to Google Polyline format
  static String encodePolyline(List<LatLng> coordinates) {
    StringBuffer encoded = StringBuffer();

    int prevLat = 0;
    int prevLng = 0;

    for (final point in coordinates) {
      int lat = (point.latitude * 1e5).round();
      int lng = (point.longitude * 1e5).round();

      int dLat = lat - prevLat;
      int dLng = lng - prevLng;

      encoded.write(_encodeValue(dLat));
      encoded.write(_encodeValue(dLng));

      prevLat = lat;
      prevLng = lng;
    }

    return encoded.toString();
  }

  static String _encodeValue(int value) {
    StringBuffer encoded = StringBuffer();
    int sgn = value < 0 ? ~(value << 1) : (value << 1);

    while (sgn >= 0x20) {
      encoded.writeCharCode((0x20 | (sgn & 0x1f)) + 63);
      sgn >>= 5;
    }

    encoded.writeCharCode(sgn + 63);
    return encoded.toString();
  }
}
