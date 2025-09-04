import 'package:equatable/equatable.dart';
import 'package:nav_e/core/domain/entities/saved_place.dart';

abstract class SavedPlacesState extends Equatable {
  const SavedPlacesState();

  @override
  List<Object?> get props => [];
}

class SavedPlacesInitial extends SavedPlacesState {}

class SavedPlacesLoading extends SavedPlacesState {}

class SavedPlacesLoaded extends SavedPlacesState {
  final List<SavedPlace> places;

  const SavedPlacesLoaded(this.places);

  @override
  List<Object?> get props => [places];
}

class SavedPlacesError extends SavedPlacesState {
  final String message;

  const SavedPlacesError(this.message);

  @override
  List<Object?> get props => [message];
}
