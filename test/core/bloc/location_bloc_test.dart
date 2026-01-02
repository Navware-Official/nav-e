import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('LocationBloc', () {
    late LocationBloc locationBloc;

    setUp(() {
      TestHelpers.setupMethodChannelMocks();
      locationBloc = LocationBloc();
    });

    tearDown(() {
      locationBloc.close();
      TestHelpers.cleanupMethodChannels();
    });

    group('initial state', () {
      test('should have correct initial state', () {
        expect(locationBloc.state.position, isNull);
        expect(locationBloc.state.heading, isNull);
        expect(locationBloc.state.tracking, isFalse);
      });
    });

    group('LocationState', () {
      test('should copy state with new values', () {
        // Arrange
        final originalState = LocationState(
          position: const LatLng(1.0, 2.0),
          heading: 90.0,
          tracking: true,
        );

        // Act
        final newState = originalState.copyWith(
          position: const LatLng(3.0, 4.0),
          heading: 180.0,
        );

        // Assert
        expect(newState.position, equals(const LatLng(3.0, 4.0)));
        expect(newState.heading, equals(180.0));
        expect(newState.tracking, isTrue); // Should preserve original value
      });

      test('should copy state with partial updates', () {
        // Arrange
        final originalState = LocationState(
          position: const LatLng(1.0, 2.0),
          heading: 90.0,
          tracking: false,
        );

        // Act
        final newState = originalState.copyWith(tracking: true);

        // Assert
        expect(newState.position, equals(const LatLng(1.0, 2.0))); // Preserved
        expect(newState.heading, equals(90.0)); // Preserved
        expect(newState.tracking, isTrue); // Updated
      });
    });

    group('StartLocationTracking', () {
      blocTest<LocationBloc, LocationState>(
        'should emit tracking state when permissions are granted',
        build: () => locationBloc,
        act: (bloc) => bloc.add(StartLocationTracking()),
        expect: () => [
          predicate<LocationState>((state) => state.tracking == true),
        ],
      );

      blocTest<LocationBloc, LocationState>(
        'should not emit when permissions are denied',
        build: () {
          // Override the mock to deny permissions
          TestHelpers.cleanupMethodChannels();
          const platform = MethodChannel('flutter.baseflow.com/geolocator');
          TestWidgetsFlutterBinding.ensureInitialized();
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(platform, (
                MethodCall methodCall,
              ) async {
                switch (methodCall.method) {
                  case 'checkPermission':
                    return 0; // LocationPermission.denied
                  case 'requestPermission':
                    return 1; // LocationPermission.deniedForever
                  case 'isLocationServiceEnabled':
                    return true;
                  default:
                    return null;
                }
              });
          return LocationBloc();
        },
        act: (bloc) => bloc.add(StartLocationTracking()),
        expect: () => [],
      );
    });

    group('StopLocationTracking', () {
      blocTest<LocationBloc, LocationState>(
        'should emit tracking false',
        build: () => locationBloc,
        seed: () => LocationState(tracking: true),
        act: (bloc) => bloc.add(StopLocationTracking()),
        expect: () => [
          predicate<LocationState>((state) => state.tracking == false),
        ],
      );
    });

    group('Events', () {
      test('StartLocationTracking should be a LocationEvent', () {
        expect(StartLocationTracking(), isA<LocationEvent>());
      });

      test('StopLocationTracking should be a LocationEvent', () {
        expect(StopLocationTracking(), isA<LocationEvent>());
      });
    });
  });
}
