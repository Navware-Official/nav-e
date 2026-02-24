import 'dart:convert';
import 'package:nav_e/core/domain/entities/trip.dart';
import 'package:nav_e/core/domain/repositories/trip_repository.dart';
import 'package:nav_e/bridge/lib.dart' as rust;

/// Rust-backed trip repository (completed route history)
class TripRepositoryRust implements ITripRepository {
  @override
  Future<List<Trip>> getAll() async {
    final json = rust.getAllTrips();
    final List<dynamic> data = jsonDecode(json);
    return data
        .map((item) => _fromRustJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Trip?> getById(int id) async {
    final json = rust.getTripById(id: id);
    if (json == 'null') return null;
    final data = jsonDecode(json) as Map<String, dynamic>;
    return _fromRustJson(data);
  }

  @override
  Future<int> insert(Trip trip) async {
    final id = rust.saveTrip(
      distanceM: trip.distanceM,
      durationSeconds: trip.durationSeconds,
      startedAt: trip.startedAt.millisecondsSinceEpoch,
      completedAt: trip.completedAt.millisecondsSinceEpoch,
      status: trip.status,
      destinationLabel: trip.destinationLabel,
      routeId: trip.routeId,
      polylineEncoded: trip.polylineEncoded,
    );
    return id.toInt();
  }

  @override
  Future<void> delete(int id) async {
    rust.deleteTrip(id: id);
  }

  Trip _fromRustJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int?,
      distanceM: (json['distance_m'] as num).toDouble(),
      durationSeconds: json['duration_seconds'] as int,
      startedAt: DateTime.fromMillisecondsSinceEpoch(json['started_at'] as int),
      completedAt: DateTime.fromMillisecondsSinceEpoch(
        json['completed_at'] as int,
      ),
      status: json['status'] as String,
      destinationLabel: json['destination_label'] as String?,
      routeId: json['route_id'] as String?,
      polylineEncoded: json['polyline_encoded'] as String?,
    );
  }
}
