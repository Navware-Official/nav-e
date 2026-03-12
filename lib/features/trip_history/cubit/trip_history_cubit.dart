import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/domain/repositories/trip_repository.dart';

import 'trip_history_state.dart';

class TripHistoryCubit extends Cubit<TripHistoryState> {
  TripHistoryCubit(this._repository) : super(TripHistoryInitial());

  final ITripRepository _repository;

  Future<void> loadTrips() async {
    emit(TripHistoryLoading());
    try {
      final trips = await _repository.getAll();
      emit(TripHistoryLoaded(trips));
    } catch (e) {
      emit(TripHistoryError(e.toString()));
    }
  }

  Future<void> deleteTrip(int id) async {
    if (state is! TripHistoryLoaded) return;
    final current = (state as TripHistoryLoaded).trips;
    await _repository.delete(id);
    emit(TripHistoryLoaded(current.where((t) => t.id != id).toList()));
  }
}
