import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Extension methods on `Map<String, String?>` to handle query parameters.
/// Includes a method to compact the map by removing null values.
/// returns `Map<String, String>`
extension QueryMapX on Map<String, String?> {
  Map<String, String> compact() {
    final out = <String, String>{};
    forEach((k, v) {
      if (v != null) out[k] = v;
    });
    return out;
  }
}

/// Extension methods on BuildContext for navigation and query parameter handling.
/// Includes methods to navigate to the home route with coordinates,
/// clear preview parameters, and retrieve the current URI and query parameters.
extension GoNavX on BuildContext {
  void goHomeWithCoords({
    required double lat,
    required double lon,
    String? label,
    String? placeId,
    int? zoom,
  }) {
    final qp = <String, String?>{
      'lat': lat.toStringAsFixed(6),
      'lon': lon.toStringAsFixed(6),
      'label': label,
      'placeId': placeId,
      'zoom': zoom?.toString(),
    }..removeWhere((_, v) => v == null);

    debugPrint(
      '[GoNavX] Navigating to home with lat=$lat lon=$lon label=$label',
    );
    goNamed('home', queryParameters: qp.cast<String, String>());
  }

  Uri currentUri() {
    final router = GoRouter.of(this);
    try {
      final loc = (router as dynamic).location as String;
      return Uri.parse(loc);
    } catch (_) {
      // Fallbacks for older versions
      final loc =
          router.routeInformationProvider.value.location ??
          router.routerDelegate.currentConfiguration.fullPath;
      return Uri.tryParse(loc) ?? Uri(path: '/');
    }
  }

  /// Get the current query parameters from the URI.
  /// returns `Map<String, String>`
  Map<String, String> currentQueryParams() => currentUri().queryParameters;
}
