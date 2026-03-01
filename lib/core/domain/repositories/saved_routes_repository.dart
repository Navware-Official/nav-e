import 'package:nav_e/core/domain/entities/saved_route.dart';

abstract class ISavedRoutesRepository {
  Future<List<SavedRoute>> getAll();
  Future<SavedRoute?> getById(int id);

  /// Parse GPX bytes to Nav-IR route JSON without saving. For preview-before-save flow.
  Future<String> parseRouteFromGpxBytes(List<int> bytes);

  /// Save a pre-parsed route (Nav-IR JSON) and return the saved entity.
  Future<SavedRoute> saveRouteFromJson(String routeJson, String source);
  Future<SavedRoute> importFromGpxBytes(List<int> bytes);
  Future<int> saveFromPlan({
    required String name,
    required List<(double, double)> waypoints,
    String? polylineEncoded,
    double? distanceM,
    int? durationS,
  });
  Future<void> delete(int id);
}
