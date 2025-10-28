import 'package:go_router/go_router.dart';
import 'package:nav_e/app/app_router.dart';

class AppNav {
  AppNav._();

  static GoRouter get _router => GoRouter.of(rootNavigatorKey.currentContext!);

  static void homeWithCoords({
    required double lat,
    required double lon,
    required String label,
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

    _router.goNamed('home', queryParameters: qp.cast<String, String>());
  }

}
