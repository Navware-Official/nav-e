import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:nav_e/features/search/bloc/search_event.dart';
import 'package:nav_e/features/search/bloc/search_state.dart';
import 'package:nav_e/core/services/geocoding_service.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final GeocodingService _geocoder;

  SearchBloc(this._geocoder) : super(SearchState()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: _debounceTransformer(const Duration(seconds: 1)),
    );
    on<SearchResultSelected>(_onResultSelected);
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty || query.length < 3) {
      emit(state.copyWith(results: [], loading: false, error: null));
      return;
    }

    emit(state.copyWith(loading: true, error: null));

    try {
      final results = await _geocoder.search(query);
      emit(state.copyWith(loading: false, results: results));
    } catch (e) {
      final errorMsg = mapExceptionToMessage(e);
      emit(state.copyWith(loading: false, error: errorMsg));
    }
  }

  Future<void> _onResultSelected(
    SearchResultSelected event,
    Emitter<SearchState> emit,
  ) async {
    final result = event.result;

    emit(state.copyWith(selected: result));
  }

  EventTransformer<T> _debounceTransformer<T>(Duration duration) {
    return (events, mapper) => events.debounce(duration).switchMap(mapper);
  }

  String mapExceptionToMessage(Object e) {
    if (e.toString().contains('403')) {
      return 'Too many requests. Please wait a moment.';
    } else if (e.toString().contains('Failed host lookup')) {
      return 'No internet connection.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }
}
