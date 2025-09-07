import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension QueryMapX on Map<String, String?> {
  Map<String, String> compact() {
    final out = <String, String>{};
    forEach((k, v) {
      if (v != null) out[k] = v; // no bang needed; promoted to non-null
    });
    return out;
  }
}

extension UriX on Uri {
  Uri withQuery({
    Map<String, String?> add = const {},
    Iterable<String> remove = const [],
  }) {
    final merged = Map<String, String>.from(queryParameters);
    for (final k in remove) {
      merged.remove(k);
    }
    add.forEach((k, v) {
      if (v != null) merged[k] = v;
    });
    return replace(queryParameters: merged);
  }
}

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
      'label': label, // do NOT manually encode
      'placeId': placeId,
      'zoom': zoom?.toString(),
    }.compact();
    goNamed('home', queryParameters: qp);
  }

  /// Clear preview-related params from the current URL (compatible with older go_router)
  void clearPreviewParams() {
    final router = GoRouter.of(this);
    final current = Uri.parse(router.location);
    final cleaned = current.withQuery(
      remove: const ['lat', 'lon', 'label', 'placeId', 'zoom'],
    );
    router.go(cleaned.toString());
  }
}
