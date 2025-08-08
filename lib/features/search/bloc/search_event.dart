import 'package:nav_e/core/models/geocoding_result.dart';

abstract class SearchEvent {}

class SearchQueryChanged extends SearchEvent {
  final String query;
  SearchQueryChanged(this.query);
}

class SearchResultSelected extends SearchEvent {
  final GeocodingResult result;
  SearchResultSelected(this.result);
}

class LoadSearchHistory extends SearchEvent {}
