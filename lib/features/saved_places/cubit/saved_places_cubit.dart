import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/domain/entities/saved_place.dart';
import 'package:nav_e/core/domain/repositories/saved_places_repository.dart';
import 'saved_places_state.dart';

class SavedPlacesCubit extends Cubit<SavedPlacesState> {
  final ISavedPlacesRepository repository;

  SavedPlacesCubit(this.repository) : super(SavedPlacesInitial());

  Future<void> loadPlaces() async {
    emit(SavedPlacesLoading());
    try {
      final places = await repository.getAll();
      emit(SavedPlacesLoaded(places));
    } catch (e) {
      emit(SavedPlacesError(e.toString()));
    }
  }

  Future<void> addPlace(SavedPlace place) async {
    try {
      await repository.insert(place);
      final updated = await repository.getAll();
      emit(SavedPlacesLoaded(updated));
    } catch (e) {
      emit(SavedPlacesError(e.toString()));
    }
  }

  Future<void> deletePlace(int id) async {
    try {
      await repository.delete(id);
      final updated = await repository.getAll();
      emit(SavedPlacesLoaded(updated));
    } catch (e) {
      emit(SavedPlacesError(e.toString()));
    }
  }
}
