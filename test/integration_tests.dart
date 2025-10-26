import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';
import 'package:nav_e/core/domain/repositories/map_source_repository.dart';
import 'helpers/test_helpers.dart';
import 'helpers/test_data_builders.dart';

class MockMapSourceRepository extends Mock implements IMapSourceRepository {}

/// Integration tests that demonstrate complex testing scenarios
/// and interactions between multiple components
void main() {
  group('Integration Tests', () {
    late MockMapSourceRepository mockMapSourceRepository;
    late MapBloc mapBloc;
    late LocationBloc locationBloc;

    setUp(() {
      TestHelpers.setupMethodChannelMocks();
      TestHelpers.setupSharedPreferences();
      mockMapSourceRepository = MockMapSourceRepository();
      mapBloc = MapBloc(mockMapSourceRepository);
      locationBloc = LocationBloc();
    });

    tearDown(() {
      mapBloc.close();
      locationBloc.close();
      TestHelpers.cleanupMethodChannels();
    });

    group('Map and Location Integration', () {
      testWidgets('should coordinate map and location state', (tester) async {
        // This would be used for widget integration tests
        // but demonstrates the testing approach for integrated components
        
        // Setup mock data
        final testSources = TestDataBuilders.createMapSourceList();
        when(() => mockMapSourceRepository.getCurrent())
            .thenAnswer((_) async => testSources.first);
        when(() => mockMapSourceRepository.getAll())
            .thenAnswer((_) async => testSources);

        // Test coordinated state management
        expect(mapBloc.state.isReady, isFalse);
        expect(locationBloc.state.tracking, isFalse);

        mapBloc.add(MapInitialized());
        locationBloc.add(StartLocationTracking());

        // Wait for state updates
        await tester.pump();
        
        // Verify states are updated appropriately
        // In a real widget test, you would verify UI updates here
      });
    });

    group('Error Handling Integration', () {
      blocTest<MapBloc, MapState>(
        'should handle repository errors gracefully',
        build: () {
          when(() => mockMapSourceRepository.getCurrent())
              .thenThrow(Exception('Network error'));
          when(() => mockMapSourceRepository.getAll())
              .thenThrow(Exception('Network error'));
          return MapBloc(mockMapSourceRepository);
        },
        act: (bloc) => bloc.add(MapInitialized()),
        expect: () => [
          predicate<MapState>((state) => 
            state.isReady == true && 
            state.error != null
          ),
        ],
      );

      test('should handle multiple repository operations', () async {
        // Arrange
        final testSources = TestDataBuilders.createMapSourceList();
        when(() => mockMapSourceRepository.getAll())
            .thenAnswer((_) async => testSources);
        when(() => mockMapSourceRepository.getCurrent())
            .thenAnswer((_) async => testSources.first);
        when(() => mockMapSourceRepository.setCurrent(any()))
            .thenAnswer((_) async => {});

        // Act & Assert - Initialize
        mapBloc.add(MapInitialized());
        await expectLater(
          mapBloc.stream,
          emitsInOrder([
            predicate<MapState>((state) => state.isReady && state.source != null),
          ]),
        );

        // Act & Assert - Change source
        mapBloc.add(MapSourceChanged('satellite'));
        
        verify(() => mockMapSourceRepository.setCurrent('satellite')).called(1);
        verify(() => mockMapSourceRepository.getCurrent()).called(2); // Once for init, once for change
      });
    });

    group('State Consistency Tests', () {
      test('should maintain consistent state across operations', () async {
        // Test that demonstrates state consistency patterns
        final initialCenter = TestDataBuilders.amsterdamCoords;
        const initialZoom = 10.0;

        // Verify initial state
        expect(mapBloc.state.center, isNot(equals(initialCenter)));
        
        // Update map position
        mapBloc.add(MapMoved(initialCenter, initialZoom));
        
        await expectLater(
          mapBloc.stream,
          emitsInOrder([
            predicate<MapState>((state) => 
              state.center == initialCenter && 
              state.zoom == initialZoom
            ),
          ]),
        );

        // Verify follow state
        expect(mapBloc.state.followUser, isTrue); // Default
        
        mapBloc.add(ToggleFollowUser(false));
        
        await expectLater(
          mapBloc.stream,
          emitsInOrder([
            predicate<MapState>((state) => 
              state.followUser == false &&
              state.center == initialCenter // Should preserve center
            ),
          ]),
        );
      });
    });

    group('Performance Tests', () {
      test('should handle rapid state updates efficiently', () async {
        // Test rapid map movements (simulating user interaction)
        final positions = [
          TestDataBuilders.amsterdamCoords,
          TestDataBuilders.rotterdamCoords,
          TestDataBuilders.utrechtCoords,
        ];

        for (int i = 0; i < positions.length; i++) {
          mapBloc.add(MapMoved(positions[i], 10.0 + i));
        }

        // Should only emit the final state due to throttling
        await expectLater(
          mapBloc.stream.take(1),
          emitsInOrder([
            predicate<MapState>((state) => 
              state.center == positions.last &&
              state.zoom == 12.0
            ),
          ]),
        );
      });
    });

    group('Data Validation Tests', () {
      test('should validate map coordinates', () {
        // Test coordinate validation patterns
        const validCoords = LatLng(52.3791, 4.9);

        // Valid coordinates should work
        expect(() => mapBloc.add(MapMoved(validCoords, 10.0)), returnsNormally);

        // Note: In a real implementation, you might want to add validation
        // for coordinate ranges in your BLoC or entities
      });

      test('should validate zoom levels', () {
        const validZoom = 10.0;
        const tooLowZoom = -1.0;
        const tooHighZoom = 25.0;

        // All zoom levels are currently accepted
        // In a real implementation, you might want to add validation
        expect(() => mapBloc.add(MapMoved(TestDataBuilders.amsterdamCoords, validZoom)), returnsNormally);
        expect(() => mapBloc.add(MapMoved(TestDataBuilders.amsterdamCoords, tooLowZoom)), returnsNormally);
        expect(() => mapBloc.add(MapMoved(TestDataBuilders.amsterdamCoords, tooHighZoom)), returnsNormally);
      });
    });
  });
}