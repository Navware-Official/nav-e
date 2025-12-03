import 'package:flutter_test/flutter_test.dart';
import 'package:nav_e/core/data/remote/map_source_repository_impl.dart';
import 'package:nav_e/core/domain/entities/map_source.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('MapSourceRepositoryImpl', () {
    late MapSourceRepositoryImpl repository;

    setUp(() {
      TestHelpers.setupSharedPreferences();
    });

    tearDown(() {
      TestHelpers.cleanupMethodChannels();
    });

    group('getCurrent', () {
      test('should return default OpenStreetMap source when no preference is set', () async {
        // Arrange
        TestHelpers.setupSharedPreferences(values: {});
        repository = MapSourceRepositoryImpl();

        // Act
        final result = await repository.getCurrent();

        // Assert
        expect(result.id, equals('osm'));
        expect(result.name, equals('OpenStreetMap'));
        expect(result.urlTemplate, equals('https://tile.openstreetmap.org/{z}/{x}/{y}.png'));
      });

      test('should return saved map source when preference exists', () async {
        // Arrange
        TestHelpers.setupSharedPreferences(values: {
          'selected_map_source_id': 'satellite'
        });
        repository = MapSourceRepositoryImpl();
        
        // Wait for the async initialization to complete
        await Future.delayed(Duration(milliseconds: 10));

        // Act
        final result = await repository.getCurrent();

        // Assert
        expect(result.id, equals('satellite'));
        expect(result.name, equals('Esri Satellite'));
      });

      test('should return default when saved preference has invalid id', () async {
        // Arrange
        TestHelpers.setupSharedPreferences(values: {
          'selected_map_source_id': 'invalid_id'
        });
        repository = MapSourceRepositoryImpl();
        
        // Wait for the async initialization to complete
        await Future.delayed(Duration(milliseconds: 10));

        // Act
        final result = await repository.getCurrent();

        // Assert
        expect(result.id, equals('osm'));
        expect(result.name, equals('OpenStreetMap'));
      });
    });

    group('getAll', () {
      test('should return all available map sources', () async {
        // Arrange
        repository = MapSourceRepositoryImpl();

        // Act
        final result = await repository.getAll();

        // Assert
        expect(result, hasLength(2));
        expect(result.any((source) => source.id == 'osm'), isTrue);
        expect(result.any((source) => source.id == 'satellite'), isTrue);
      });

      test('should return map sources with correct properties', () async {
        // Arrange
        repository = MapSourceRepositoryImpl();

        // Act
        final result = await repository.getAll();

        // Assert
        final osmSource = result.firstWhere((s) => s.id == 'osm');
        expect(osmSource.name, equals('OpenStreetMap'));
        expect(osmSource.maxZoom, equals(19));
        expect(osmSource.headers, isNotNull);
        expect(osmSource.headers!['User-Agent'], equals('nav-e/1.0 (info@navware.org)'));

        final satelliteSource = result.firstWhere((s) => s.id == 'satellite');
        expect(satelliteSource.name, equals('Esri Satellite'));
        expect(satelliteSource.attribution, isNotNull);
        expect(satelliteSource.attribution, contains('Esri'));
      });
    });

    group('setCurrent', () {
      test('should save valid map source id to preferences', () async {
        // Arrange
        TestHelpers.setupSharedPreferences(values: {});
        repository = MapSourceRepositoryImpl();

        // Act
        await repository.setCurrent('satellite');
        final result = await repository.getCurrent();

        // Assert
        expect(result.id, equals('satellite'));
      });

      test('should not save invalid map source id', () async {
        // Arrange
        TestHelpers.setupSharedPreferences(values: {});
        repository = MapSourceRepositoryImpl();

        // Act
        await repository.setCurrent('invalid_id');
        final result = await repository.getCurrent();

        // Assert
        expect(result.id, equals('osm')); // Should remain default
      });

      test('should update preference when switching between valid sources', () async {
        // Arrange
        TestHelpers.setupSharedPreferences(values: {});
        repository = MapSourceRepositoryImpl();

        // Act & Assert - Set to satellite
        await repository.setCurrent('satellite');
        var result = await repository.getCurrent();
        expect(result.id, equals('satellite'));

        // Act & Assert - Switch back to OSM
        await repository.setCurrent('osm');
        result = await repository.getCurrent();
        expect(result.id, equals('osm'));
      });
    });

    group('MapSource entity', () {
      test('should create map source with required properties', () {
        // Arrange & Act
        const mapSource = MapSource(
          id: 'test',
          name: 'Test Source',
          urlTemplate: 'https://test.com/{z}/{x}/{y}.png',
        );

        // Assert
        expect(mapSource.id, equals('test'));
        expect(mapSource.name, equals('Test Source'));
        expect(mapSource.urlTemplate, equals('https://test.com/{z}/{x}/{y}.png'));
        expect(mapSource.minZoom, equals(0)); // Default value
        expect(mapSource.maxZoom, equals(19)); // Default value
        expect(mapSource.isWms, isFalse); // Default value
      });

      test('should create map source with optional properties', () {
        // Arrange & Act
        const mapSource = MapSource(
          id: 'test',
          name: 'Test Source',
          urlTemplate: 'https://test.com/{z}/{x}/{y}.png',
          description: 'Test description',
          minZoom: 5,
          maxZoom: 15,
          attribution: 'Test attribution',
          headers: {'User-Agent': 'test'},
          queryParams: {'key': 'value'},
          isWms: true,
        );

        // Assert
        expect(mapSource.description, equals('Test description'));
        expect(mapSource.minZoom, equals(5));
        expect(mapSource.maxZoom, equals(15));
        expect(mapSource.attribution, equals('Test attribution'));
        expect(mapSource.headers, equals({'User-Agent': 'test'}));
        expect(mapSource.queryParams, equals({'key': 'value'}));
        expect(mapSource.isWms, isTrue);
      });
    });
  });
}