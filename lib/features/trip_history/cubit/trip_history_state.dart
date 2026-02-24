import 'package:nav_e/core/domain/entities/trip.dart';

abstract class TripHistoryState {}

class TripHistoryInitial extends TripHistoryState {}

class TripHistoryLoading extends TripHistoryState {}

class TripHistoryLoaded extends TripHistoryState {
  final List<Trip> trips;

  TripHistoryLoaded(this.trips);
}

class TripHistoryError extends TripHistoryState {
  final String message;

  TripHistoryError(this.message);
}
