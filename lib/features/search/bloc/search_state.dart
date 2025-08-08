import 'package:nav_e/core/models/geocoding_result.dart';

class SearchState {
  final bool loading;
  final List<GeocodingResult> results;
  final List<GeocodingResult> history;
  final String? error;
  final GeocodingResult? selected;

  SearchState({
    this.loading = false,
    this.results = const [],
    this.history = const [],
    this.error,
    this.selected,
  });

  SearchState copyWith({
    bool? loading,
    List<GeocodingResult>? results,
    List<GeocodingResult>? history,
    String? error,
    GeocodingResult? selected,
  }) {
    return SearchState(
      loading: loading ?? this.loading,
      results: results ?? this.results,
      history: history ?? this.history,
      error: error,
      selected: selected ?? this.selected,
    );
  }
}
