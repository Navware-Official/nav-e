import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:nav_e/core/domain/repositories/geocoding_respository.dart';
import 'package:stream_transform/stream_transform.dart';

import 'package:nav_e/features/search/bloc/search_event.dart';
import 'package:nav_e/features/search/bloc/search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final IGeocodingRepository _geocoder;

  SearchBloc(this._geocoder) : super(SearchState()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: _debounceRestartable(const Duration(milliseconds: 350)),
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
      final results = await _geocoder.search(query, limit: 10);
      emit(state.copyWith(loading: false, results: results));
    } catch (e) {
      emit(state.copyWith(loading: false, error: _mapExceptionToMessage(e)));
    }
  }

  Future<void> _onResultSelected(
    SearchResultSelected event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(selected: event.result));
  }

  // Debounce + cancel in-flight when a new event arrives
  EventTransformer<T> _debounceRestartable<T>(Duration d) {
    return (events, mapper) =>
        restartable<T>().call(events.debounce(d), mapper);
  }

  String _mapExceptionToMessage(Object e) {
    final s = e.toString();
    if (s.contains('429') || s.contains('Too Many Requests')) {
      return 'Too many requests. Please wait a moment.';
    } else if (s.contains('403')) {
      return 'Request blocked. Try again shortly.';
    } else if (s.contains('Failed host lookup') ||
        s.contains('SocketException')) {
      return 'No internet connection.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }
}
