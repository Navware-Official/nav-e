import 'package:mocktail/mocktail.dart';
import 'package:nav_e/core/domain/repositories/map_source_repository.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';
import 'package:nav_e/core/domain/repositories/saved_places_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Repository mocks
class MockMapSourceRepository extends Mock implements IMapSourceRepository {}
class MockGeocodingRepository extends Mock implements IGeocodingRepository {}
class MockSavedPlacesRepository extends Mock implements ISavedPlacesRepository {}

// Platform service mocks
class MockSharedPreferences extends Mock implements SharedPreferences {}