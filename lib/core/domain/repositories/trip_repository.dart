import 'package:nav_e/core/domain/entities/trip.dart';

abstract class ITripRepository {
  Future<List<Trip>> getAll();
  Future<Trip?> getById(int id);
  Future<int> insert(Trip trip);
  Future<void> delete(int id);
}
