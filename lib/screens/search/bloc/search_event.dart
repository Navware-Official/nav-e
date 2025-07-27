import 'package:nav_e/services/geocoding_service.dart';

abstract class SearchEvent {}

class SearchQueryChanged extends SearchEvent {
  final String query;
  SearchQueryChanged(this.query);
}

class SearchResultSelected extends SearchEvent {
  final GeocodingResult result;
  SearchResultSelected(this.result);
}
