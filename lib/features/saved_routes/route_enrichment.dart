import 'dart:convert';

import 'package:nav_e/core/domain/entities/saved_route.dart';

/// Lightweight enrichment data parsed from route JSON (for list subtitles).
/// Used from a background isolate to avoid blocking the UI.
class RouteEnrichment {
  const RouteEnrichment({this.distanceKm, this.durationMinutes, this.country});

  final double? distanceKm;
  final int? durationMinutes;
  final String? country;
}

/// Top-level function for [compute]. Parses route JSON in a background isolate.
List<RouteEnrichment> parseRoutesEnrichment(List<SavedRoute> routes) {
  return routes.map((route) {
    double? distanceKm;
    int? durationMinutes;
    String? country;
    try {
      final map = jsonDecode(route.routeJson) as Map<String, dynamic>;
      final metadata = map['metadata'] as Map<String, dynamic>? ?? {};
      final distM = (metadata['total_distance_m'] as num?)?.toDouble();
      if (distM != null) distanceKm = distM / 1000;
      final durS = (metadata['estimated_duration_s'] as num?)?.toInt();
      if (durS != null) durationMinutes = durS ~/ 60;
      final source = metadata['source'] as Map<String, dynamic>?;
      final extras = source?['extras'] as Map<String, dynamic>?;
      country = extras?['country'] as String?;
    } catch (_) {}
    return RouteEnrichment(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      country: country,
    );
  }).toList();
}
