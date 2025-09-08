import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension QueryMapX on Map<String, String?> {
  Map<String, String> compact() {
    final out = <String, String>{};
    forEach((k, v) {
      if (v != null) out[k] = v;
    });
    return out;
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
      'label': label,
      'placeId': placeId,
      'zoom': zoom?.toString(),
    }.compact();

    goNamed('home', queryParameters: qp);
  }

  void clearPreviewParams() {
    goNamed('home');
  }
}
