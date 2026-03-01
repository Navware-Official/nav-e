import 'dart:convert';

import 'package:nav_e/bridge/lib.dart' as rust;
import 'package:nav_e/core/domain/entities/saved_route.dart';
import 'package:nav_e/core/domain/repositories/saved_routes_repository.dart';

/// Rust-backed saved routes repository.
class SavedRoutesRepositoryRust implements ISavedRoutesRepository {
  @override
  Future<List<SavedRoute>> getAll() async {
    final json = rust.getAllSavedRoutes();
    final List<dynamic> data = jsonDecode(json);
    return data
        .map((item) => _fromRustJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SavedRoute?> getById(int id) async {
    final json = rust.getSavedRouteById(id: id);
    if (json == 'null') return null;
    final data = jsonDecode(json) as Map<String, dynamic>;
    return _fromRustJson(data);
  }

  @override
  Future<String> parseRouteFromGpxBytes(List<int> bytes) async {
    return rust.parseRouteFromGpx(bytes: bytes);
  }

  @override
  Future<SavedRoute> saveRouteFromJson(String routeJson, String source) async {
    final json = rust.saveRouteFromJson(routeJson: routeJson, source: source);
    final data = jsonDecode(json) as Map<String, dynamic>;
    return _fromRustJson(data);
  }

  @override
  Future<SavedRoute> importFromGpxBytes(List<int> bytes) async {
    final json = rust.importRouteFromGpx(bytes: bytes);
    final data = jsonDecode(json) as Map<String, dynamic>;
    return _fromRustJson(data);
  }

  @override
  Future<int> saveFromPlan({
    required String name,
    required List<(double, double)> waypoints,
    String? polylineEncoded,
    double? distanceM,
    int? durationS,
  }) async {
    final id = rust.saveRouteFromPlan(
      name: name,
      waypoints: waypoints,
      polylineEncoded: polylineEncoded,
      distanceM: distanceM,
      durationS: durationS != null ? BigInt.from(durationS) : null,
    );
    return id.toInt();
  }

  @override
  Future<void> delete(int id) async {
    rust.deleteSavedRoute(id: id);
  }

  SavedRoute _fromRustJson(Map<String, dynamic> json) {
    return SavedRoute(
      id: json['id'] as int?,
      name: json['name'] as String,
      routeJson: json['route_json'] as String,
      source: json['source'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['created_at'] as int) * 1000,
      ),
    );
  }
}
