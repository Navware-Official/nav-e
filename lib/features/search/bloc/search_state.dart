import 'package:nav_e/core/models/geocoding_result.dart';

class SearchState {
  final bool loading;
  final List<GeocodingResult> results;
  final String? error;
  final GeocodingResult? selected;

  SearchState({
    this.loading = false,
    this.results = const [],
    this.error,
    this.selected,
  });

  SearchState copyWith({
    bool? loading,
    List<GeocodingResult>? results,
    String? error,
    GeocodingResult? selected,
  }) {
    return SearchState(
      loading: loading ?? this.loading,
      results: results ?? this.results,
      error: error,
      selected: selected ?? this.selected,
    );
  }
}
