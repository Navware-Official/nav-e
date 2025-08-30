import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'saved_places_state.dart';

class SavedPlacesCubit extends Cubit<SavedPlacesState> {
  SavedPlacesCubit() : super(SavedPlacesInitial());
}
