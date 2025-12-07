import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_e/bridge/api_v2.dart';
import 'package:nav_e/bridge/frb_generated.dart';

void main() {
  setUpAll(() async {
    // Initialize Flutter Rust Bridge before running tests
    await RustBridge.init();
  });

  group('Geocode API Tests', () {
    test('geocodeSearch returns valid results for a known location', () async {
      // Arrange
      const query = 'Berlin, Germany';
      const limit = 5;

      // Act
      final resultJson = await geocodeSearch(query: query, limit: limit);
      final results = jsonDecode(resultJson) as List<dynamic>;

      // Assert
      expect(results, isNotEmpty, reason: 'Should return at least one result');
      expect(results.length, lessThanOrEqualTo(limit),
          reason: 'Should respect the limit parameter');

      // Verify result structure
      final firstResult = results.first as Map<String, dynamic>;
      expect(firstResult, containsPair('latitude', isA<double>()));
      expect(firstResult, containsPair('longitude', isA<double>()));
      expect(firstResult, containsPair('display_name', isA<String>()));

      // Verify coordinates are in valid range for Berlin
      final lat = firstResult['latitude'] as double;
      final lon = firstResult['longitude'] as double;
      expect(lat, inInclusiveRange(52.0, 53.0),
          reason: 'Berlin latitude should be around 52.5°N');
      expect(lon, inInclusiveRange(13.0, 14.0),
          reason: 'Berlin longitude should be around 13.4°E');
    });

    test('geocodeSearch handles multiple results', () async {
      // Arrange
      const query = 'Paris';
      const limit = 10;

      // Act
      final resultJson = await geocodeSearch(query: query, limit: limit);
      final results = jsonDecode(resultJson) as List<dynamic>;

      // Assert
      expect(results, isNotEmpty);
      expect(results.length, lessThanOrEqualTo(limit));

      // Verify all results have required fields
      for (final result in results) {
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['latitude'], isA<double>());
        expect(resultMap['longitude'], isA<double>());
        expect(resultMap['display_name'], isA<String>());
      }
    });

    test('geocodeSearch respects different limit values', () async {
      // Arrange
      const query = 'London';

      // Act & Assert for limit = 1
      final result1Json = await geocodeSearch(query: query, limit: 1);
      final results1 = jsonDecode(result1Json) as List<dynamic>;
      expect(results1.length, equals(1));

      // Act & Assert for limit = 3
      final result3Json = await geocodeSearch(query: query, limit: 3);
      final results3 = jsonDecode(result3Json) as List<dynamic>;
      expect(results3.length, lessThanOrEqualTo(3));

      // Act & Assert for no limit (should default to 10)
      final resultDefaultJson = await geocodeSearch(query: query);
      final resultsDefault = jsonDecode(resultDefaultJson) as List<dynamic>;
      expect(resultsDefault.length, lessThanOrEqualTo(10));
    });

    test('geocodeSearch handles specific addresses', () async {
      // Arrange
      const query = 'Eiffel Tower, Paris';

      // Act
      final resultJson = await geocodeSearch(query: query, limit: 1);
      final results = jsonDecode(resultJson) as List<dynamic>;

      // Assert
      expect(results, isNotEmpty);
      final result = results.first as Map<String, dynamic>;
      final lat = result['latitude'] as double;
      final lon = result['longitude'] as double;

      // Eiffel Tower coordinates: approximately 48.858°N, 2.294°E
      expect(lat, inInclusiveRange(48.8, 48.9),
          reason: 'Eiffel Tower latitude should be around 48.858°N');
      expect(lon, inInclusiveRange(2.2, 2.4),
          reason: 'Eiffel Tower longitude should be around 2.294°E');
    });

    test('geocodeSearch handles empty query gracefully', () async {
      // Arrange
      const query = '';

      // Act & Assert
      expect(
        () async => await geocodeSearch(query: query),
        throwsA(isA<Exception>()),
        reason: 'Empty query should throw an exception',
      );
    });

    test('geocodeSearch handles non-existent location', () async {
      // Arrange
      const query = 'xyznonexistentplace12345';

      // Act
      final resultJson = await geocodeSearch(query: query, limit: 5);
      final results = jsonDecode(resultJson) as List<dynamic>;

      // Assert - might return empty or very generic results
      // The API behavior here depends on the geocoding service
      expect(results, isA<List>());
    });

    test('reverseGeocode returns address for valid coordinates', () async {
      // Arrange - Brandenburg Gate coordinates
      const latitude = 52.5163;
      const longitude = 13.3777;

      // Act
      final address = await reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );

      // Assert
      expect(address, isNotEmpty);
      expect(address, isA<String>());
      // The exact format depends on the geocoding service
      print('Reverse geocoded address: $address');
    });

    test('reverseGeocode handles Eiffel Tower coordinates', () async {
      // Arrange
      const latitude = 48.8584;
      const longitude = 2.2945;

      // Act
      final address = await reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );

      // Assert
      expect(address, isNotEmpty);
      expect(address, isA<String>());
      print('Reverse geocoded address: $address');
    });

    test('reverseGeocode handles ocean coordinates', () async {
      // Arrange - Middle of Atlantic Ocean
      const latitude = 30.0;
      const longitude = -40.0;

      // Act
      final address = await reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );

      // Assert - Might return empty or generic ocean name
      expect(address, isA<String>());
      print('Ocean reverse geocode: $address');
    });

    test('reverseGeocode rejects invalid latitude', () async {
      // Arrange - Invalid latitude (> 90)
      const latitude = 95.0;
      const longitude = 0.0;

      // Act & Assert
      expect(
        () async => await reverseGeocode(
          latitude: latitude,
          longitude: longitude,
        ),
        throwsA(isA<Exception>()),
        reason: 'Invalid latitude should throw an exception',
      );
    });

    test('reverseGeocode rejects invalid longitude', () async {
      // Arrange - Invalid longitude (> 180)
      const latitude = 0.0;
      const longitude = 190.0;

      // Act & Assert
      expect(
        () async => await reverseGeocode(
          latitude: latitude,
          longitude: longitude,
        ),
        throwsA(isA<Exception>()),
        reason: 'Invalid longitude should throw an exception',
      );
    });

    test('geocodeSearch and reverseGeocode are consistent', () async {
      // Arrange
      const query = 'Tokyo, Japan';

      // Act - Forward geocode
      final forwardJson = await geocodeSearch(query: query, limit: 1);
      final forwardResults = jsonDecode(forwardJson) as List<dynamic>;
      expect(forwardResults, isNotEmpty);

      final forwardResult = forwardResults.first as Map<String, dynamic>;
      final lat = forwardResult['latitude'] as double;
      final lon = forwardResult['longitude'] as double;

      // Act - Reverse geocode the result
      final reverseAddress = await reverseGeocode(
        latitude: lat,
        longitude: lon,
      );

      // Assert
      expect(reverseAddress, isNotEmpty);
      expect(reverseAddress, isA<String>());
      print('Forward: $query -> ($lat, $lon)');
      print('Reverse: ($lat, $lon) -> $reverseAddress');
    });
  });

  group('Geocode API Edge Cases', () {
    test('handles city names with special characters', () async {
      // Arrange
      const query = 'São Paulo, Brazil';

      // Act
      final resultJson = await geocodeSearch(query: query, limit: 1);
      final results = jsonDecode(resultJson) as List<dynamic>;

      // Assert
      expect(results, isNotEmpty);
    });

    test('handles very long query strings', () async {
      // Arrange
      final query = 'A' * 500; // Very long string

      // Act & Assert
      // Should either handle gracefully or throw exception
      try {
        final resultJson = await geocodeSearch(query: query, limit: 1);
        final results = jsonDecode(resultJson) as List<dynamic>;
        expect(results, isA<List>());
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });

    test('handles limit edge cases', () async {
      // Arrange
      const query = 'New York';

      // Act & Assert for limit = 0
      final result0Json = await geocodeSearch(query: query, limit: 0);
      final results0 = jsonDecode(result0Json) as List<dynamic>;
      expect(results0, isEmpty);

      // Act & Assert for very large limit
      final result100Json = await geocodeSearch(query: query, limit: 100);
      final results100 = jsonDecode(result100Json) as List<dynamic>;
      expect(results100, isA<List>());
    });

    test('handles coordinates at boundaries', () async {
      // North Pole
      final northPole = await reverseGeocode(latitude: 90.0, longitude: 0.0);
      expect(northPole, isA<String>());

      // South Pole
      final southPole = await reverseGeocode(latitude: -90.0, longitude: 0.0);
      expect(southPole, isA<String>());

      // International Date Line
      final dateLine = await reverseGeocode(latitude: 0.0, longitude: 180.0);
      expect(dateLine, isA<String>());

      // Prime Meridian & Equator
      final zeroZero = await reverseGeocode(latitude: 0.0, longitude: 0.0);
      expect(zeroZero, isA<String>());
    });
  });
}
