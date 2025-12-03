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

    if (currentUri().path == '/' &&
        currentUri().queryParameters.toString() ==
            qp.entries.where((e) => e.value != null).toSet().toString()) {
      return;
    }

    goNamed('home', queryParameters: qp.cast<String, String>());
  }

  Uri currentUri() {
    final router = GoRouter.of(this);
    final loc = (router as dynamic).location as String;
    return Uri.parse(loc);
  }

  /// Get the current query parameters from the URI.
  /// returns `Map<String, String>`
  Map<String, String> currentQueryParams() => currentUri().queryParameters;
}
