import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nav_e/core/domain/entities/map_source.dart';
import 'package:nav_e/core/domain/repositories/map_source_repository.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';

class MockMapSourceRepository extends Mock implements IMapSourceRepository {}

void main() {
  group('MapBloc', () {
    late MockMapSourceRepository mockMapSourceRepository;
    late MapBloc mapBloc;

    const testMapSource1 = MapSource(
      id: 'osm',
      name: 'OpenStreetMap',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );

    const testMapSource2 = MapSource(
      id: 'satellite',
      name: 'Satellite',
      urlTemplate: 'https://satellite.example.com/{z}/{x}/{y}.png',
    );

    const testMapSources = [testMapSource1, testMapSource2];

    setUp(() {
      mockMapSourceRepository = MockMapSourceRepository();
      mapBloc = MapBloc(mockMapSourceRepository);
    });

    tearDown(() {
      mapBloc.close();
    });

    group('initial state', () {
      test('should have correct initial state', () {
        expect(mapBloc.state.center, equals(LatLng(52.3791, 4.9)));
        expect(mapBloc.state.zoom, equals(13.0));
        expect(mapBloc.state.isReady, isFalse);
        expect(mapBloc.state.followUser, isTrue);
        expect(mapBloc.state.source, isNull);
        expect(mapBloc.state.available, isEmpty);
        expect(mapBloc.state.loadingSource, isFalse);
        expect(mapBloc.state.error, isNull);
      });
    });

    group('MapState', () {
      test('should copy state with new values', () {
        // Arrange
        final originalState = MapState(
          center: const LatLng(1.0, 2.0),
          zoom: 10.0,
          isReady: false,
          followUser: true,
          source: testMapSource1,
          available: const [testMapSource1],
          loadingSource: false,
        );

        // Act
        final newState = originalState.copyWith(
          center: const LatLng(3.0, 4.0),
          zoom: 15.0,
          isReady: true,
          followUser: false,
        );

        // Assert
        expect(newState.center, equals(const LatLng(3.0, 4.0)));
        expect(newState.zoom, equals(15.0));
        expect(newState.isReady, isTrue);
        expect(newState.followUser, isFalse);
        expect(newState.source, equals(testMapSource1)); // Preserved
        expect(newState.available, equals([testMapSource1])); // Preserved
        expect(newState.loadingSource, isFalse); // Preserved
      });

      test('should handle error parameter correctly in copyWith', () {
        // Arrange
        final originalState = MapState(
          center: const LatLng(1.0, 2.0),
          zoom: 10.0,
          isReady: true,
        );

        // Act
        final stateWithError = originalState.copyWith(error: 'Test error');
        final stateWithoutError = stateWithError.copyWith(error: null);

        // Assert
        expect(stateWithError.error, equals('Test error'));
        expect(stateWithoutError.error, isNull);
      });
    });

    group('MapInitialized', () {
      blocTest<MapBloc, MapState>(
        'should emit ready state with map sources when initialization succeeds',
        build: () {
          when(
            () => mockMapSourceRepository.getCurrent(),
          ).thenAnswer((_) async => testMapSource1);
          when(
            () => mockMapSourceRepository.getAll(),
          ).thenAnswer((_) async => testMapSources);
          return MapBloc(mockMapSourceRepository);
        },
        act: (bloc) => bloc.add(MapInitialized()),
        expect: () => [
          predicate<MapState>(
            (state) =>
                state.isReady == true &&
                state.source == testMapSource1 &&
                state.available.length == 2 &&
                state.error == null,
          ),
        ],
        verify: (_) {
          verify(() => mockMapSourceRepository.getCurrent()).called(1);
          verify(() => mockMapSourceRepository.getAll()).called(1);
        },
      );

      blocTest<MapBloc, MapState>(
        'should emit ready state with error when initialization fails',
        build: () {
          when(
            () => mockMapSourceRepository.getCurrent(),
          ).thenThrow(Exception('Failed to load sources'));
          return MapBloc(mockMapSourceRepository);
        },
        act: (bloc) => bloc.add(MapInitialized()),
        expect: () => [
          predicate<MapState>(
            (state) => state.isReady == true && state.error != null,
          ),
        ],
      );
    });

    group('MapMoved', () {
      blocTest<MapBloc, MapState>(
        'should update center and zoom',
        build: () => mapBloc,
        seed: () => MapState(
          center: const LatLng(52.3791, 4.9),
          zoom: 13.0,
          isReady: true,
          followUser: false,
        ),
        act: (bloc) => bloc.add(MapMoved(const LatLng(50.0, 60.0), 15.0)),
        expect: () => [
          predicate<MapState>(
            (state) =>
                state.center == const LatLng(50.0, 60.0) && state.zoom == 15.0,
          ),
        ],
      );
    });

    group('ToggleFollowUser', () {
      blocTest<MapBloc, MapState>(
        'should update followUser to false',
        build: () => mapBloc,
        act: (bloc) => bloc.add(ToggleFollowUser(false)),
        expect: () => [
          predicate<MapState>((state) => state.followUser == false),
        ],
      );

      blocTest<MapBloc, MapState>(
        'should update followUser to true',
        build: () => mapBloc,
        seed: () => MapState(
          center: const LatLng(52.3791, 4.9),
          zoom: 13.0,
          isReady: true,
          followUser: false,
        ),
        act: (bloc) => bloc.add(ToggleFollowUser(true)),
        expect: () => [
          predicate<MapState>((state) => state.followUser == true),
        ],
      );
    });

    group('MapSourceChanged', () {
      blocTest<MapBloc, MapState>(
        'should update map source when change succeeds',
        build: () {
          when(
            () => mockMapSourceRepository.setCurrent(any()),
          ).thenAnswer((_) async => {});
          when(
            () => mockMapSourceRepository.getCurrent(),
          ).thenAnswer((_) async => testMapSource2);
          return MapBloc(mockMapSourceRepository);
        },
        act: (bloc) => bloc.add(MapSourceChanged('satellite')),
        expect: () => [
          predicate<MapState>(
            (state) => state.loadingSource == true && state.error == null,
          ),
          predicate<MapState>(
            (state) =>
                state.source == testMapSource2 && state.loadingSource == false,
          ),
        ],
        verify: (_) {
          verify(
            () => mockMapSourceRepository.setCurrent('satellite'),
          ).called(1);
          verify(() => mockMapSourceRepository.getCurrent()).called(1);
        },
      );

      blocTest<MapBloc, MapState>(
        'should emit error state when source change fails',
        build: () {
          when(
            () => mockMapSourceRepository.setCurrent(any()),
          ).thenThrow(Exception('Failed to change source'));
          return MapBloc(mockMapSourceRepository);
        },
        act: (bloc) => bloc.add(MapSourceChanged('invalid')),
        expect: () => [
          predicate<MapState>(
            (state) => state.loadingSource == true && state.error == null,
          ),
          predicate<MapState>(
            (state) => state.loadingSource == false && state.error != null,
          ),
        ],
      );
    });

    group('Events', () {
      test('MapInitialized should be a MapEvent', () {
        expect(MapInitialized(), isA<MapEvent>());
      });

      test('MapMoved should be a MapEvent with correct properties', () {
        final event = MapMoved(const LatLng(1.0, 2.0), 10.0);
        expect(event, isA<MapEvent>());
        expect(event.center, equals(const LatLng(1.0, 2.0)));
        expect(event.zoom, equals(10.0));
      });

      test('ToggleFollowUser should be a MapEvent with correct property', () {
        final event = ToggleFollowUser(true);
        expect(event, isA<MapEvent>());
        expect(event.follow, isTrue);
      });

      test('MapSourceChanged should be a MapEvent with correct property', () {
        final event = MapSourceChanged('osm');
        expect(event, isA<MapEvent>());
        expect(event.sourceId, equals('osm'));
      });
    });
  });
}
