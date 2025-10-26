import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nav_e/core/domain/entities/device.dart';
import 'package:nav_e/core/domain/repositories/device_repository.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';

class MockDeviceRepository extends Mock implements IDeviceRepository {}

void main() {
  group('DevicesBloc', () {
    late MockDeviceRepository mockDeviceRepository;
    late DevicesBloc devicesBloc;

    const testDevice1 = Device(
      id: 1,
      name: 'GPS Navigator',
      model: 'NavTech 3000',
      remoteId: 'AA:BB:CC:DD:EE:FF',
    );

    const testDevice2 = Device(
      id: 2,
      name: 'Bluetooth Tracker',
      model: 'TrackTech Pro',
      remoteId: 'FF:EE:DD:CC:BB:AA',
    );

    const testDevices = [testDevice1, testDevice2];

    setUp(() {
      mockDeviceRepository = MockDeviceRepository();
      devicesBloc = DevicesBloc(mockDeviceRepository);
      
      // Register fallback values for Mocktail
      registerFallbackValue(testDevice1);
    });

    tearDown(() {
      devicesBloc.close();
    });

    group('initial state', () {
      test('should have correct initial state', () {
        expect(devicesBloc.state, equals(DeviceInitial()));
      });
    });

    group('LoadDevices', () {
      blocTest<DevicesBloc, DevicesState>(
        'should emit success state when devices are loaded successfully',
        build: () {
          when(() => mockDeviceRepository.getAll())
              .thenAnswer((_) async => testDevices);
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(LoadDevices()),
        expect: () => [
          DeviceLoadInProgress(),
          const DeviceLoadSuccess(testDevices),
        ],
        verify: (_) {
          verify(() => mockDeviceRepository.getAll()).called(1);
        },
      );

      blocTest<DevicesBloc, DevicesState>(
        'should emit failure state when loading devices fails',
        build: () {
          when(() => mockDeviceRepository.getAll())
              .thenThrow(Exception('Database error'));
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(LoadDevices()),
        expect: () => [
          DeviceLoadInProgress(),
          predicate<DeviceOperationFailure>((state) => 
            state.message.contains('Failed to load devices')
          ),
        ],
      );

      blocTest<DevicesBloc, DevicesState>(
        'should emit empty list when no devices exist',
        build: () {
          when(() => mockDeviceRepository.getAll())
              .thenAnswer((_) async => []);
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(LoadDevices()),
        expect: () => [
          DeviceLoadInProgress(),
          const DeviceLoadSuccess([]),
        ],
      );
    });

    group('AddDevice', () {
      const newDevice = Device(
        name: 'New Device',
        model: 'New Model',
        remoteId: 'NEW:REMOTE:ID',
      );

      const addedDevice = Device(
        id: 3,
        name: 'New Device',
        model: 'New Model',
        remoteId: 'NEW:REMOTE:ID',
      );

      blocTest<DevicesBloc, DevicesState>(
        'should emit success state when device is added successfully',
        build: () {
          when(() => mockDeviceRepository.existsByRemoteId(any()))
              .thenAnswer((_) async => false);
          when(() => mockDeviceRepository.insert(any()))
              .thenAnswer((_) async => 3);
          when(() => mockDeviceRepository.getById(3))
              .thenAnswer((_) async => addedDevice);
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(const AddDevice(newDevice)),
        expect: () => [
          DeviceOperationInProgress(),
          const DeviceOperationSuccess("Device added successfully", addedDevice),
        ],
        verify: (_) {
          verify(() => mockDeviceRepository.existsByRemoteId('NEW:REMOTE:ID')).called(1);
          verify(() => mockDeviceRepository.insert(newDevice)).called(1);
          verify(() => mockDeviceRepository.getById(3)).called(1);
        },
      );

      blocTest<DevicesBloc, DevicesState>(
        'should emit failure state when device with same remote ID exists',
        build: () {
          when(() => mockDeviceRepository.existsByRemoteId(any()))
              .thenAnswer((_) async => true);
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(const AddDevice(newDevice)),
        expect: () => [
          DeviceOperationInProgress(),
          const DeviceOperationFailure("Device with this remote ID already exists"),
        ],
        verify: (_) {
          verify(() => mockDeviceRepository.existsByRemoteId('NEW:REMOTE:ID')).called(1);
          verifyNever(() => mockDeviceRepository.insert(any()));
        },
      );

      blocTest<DevicesBloc, DevicesState>(
        'should add device without remote ID check when remote ID is null',
        build: () {
          const addedSimpleDevice = Device(id: 4, name: 'Simple Device');
          
          when(() => mockDeviceRepository.insert(any()))
              .thenAnswer((_) async => 4);
          when(() => mockDeviceRepository.getById(4))
              .thenAnswer((_) async => addedSimpleDevice);
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(const AddDevice(Device(name: 'Simple Device'))),
        expect: () => [
          DeviceOperationInProgress(),
          const DeviceOperationSuccess("Device added successfully", Device(id: 4, name: 'Simple Device')),
        ],
        verify: (_) {
          verifyNever(() => mockDeviceRepository.existsByRemoteId(any()));
        },
      );

      blocTest<DevicesBloc, DevicesState>(
        'should emit failure state when insertion fails',
        build: () {
          when(() => mockDeviceRepository.existsByRemoteId(any()))
              .thenAnswer((_) async => false);
          when(() => mockDeviceRepository.insert(any()))
              .thenThrow(Exception('Database error'));
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(const AddDevice(newDevice)),
        expect: () => [
          DeviceOperationInProgress(),
          predicate<DeviceOperationFailure>((state) => 
            state.message.contains('Failed to add device')
          ),
        ],
      );
    });

    group('UpdateDevice', () {
      const updatedDevice = Device(
        id: 1,
        name: 'Updated GPS Navigator',
        model: 'NavTech 4000',
        remoteId: 'AA:BB:CC:DD:EE:FF',
      );

      blocTest<DevicesBloc, DevicesState>(
        'should emit success state when device is updated successfully',
        build: () {
          when(() => mockDeviceRepository.update(any()))
              .thenAnswer((_) async => 1);
          when(() => mockDeviceRepository.getById(1))
              .thenAnswer((_) async => updatedDevice);
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(const UpdateDevice(updatedDevice)),
        expect: () => [
          DeviceOperationInProgress(),
          const DeviceOperationSuccess("Device updated successfully", updatedDevice),
        ],
        verify: (_) {
          verify(() => mockDeviceRepository.update(updatedDevice)).called(1);
          verify(() => mockDeviceRepository.getById(1)).called(1);
        },
      );

      blocTest<DevicesBloc, DevicesState>(
        'should emit failure state when device not found',
        build: () {
          when(() => mockDeviceRepository.update(any()))
              .thenAnswer((_) async => 0);
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(const UpdateDevice(updatedDevice)),
        expect: () => [
          DeviceOperationInProgress(),
          const DeviceOperationFailure("Device not found or no changes made"),
        ],
      );

      blocTest<DevicesBloc, DevicesState>(
        'should emit failure state when update fails',
        build: () {
          when(() => mockDeviceRepository.update(any()))
              .thenThrow(Exception('Database error'));
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(const UpdateDevice(updatedDevice)),
        expect: () => [
          DeviceOperationInProgress(),
          predicate<DeviceOperationFailure>((state) => 
            state.message.contains('Failed to update device')
          ),
        ],
      );
    });

    group('DeleteDevice', () {
      blocTest<DevicesBloc, DevicesState>(
        'should emit success state when device is deleted successfully',
        build: () {
          when(() => mockDeviceRepository.delete(any()))
              .thenAnswer((_) async => 1);
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(const DeleteDevice(1)),
        expect: () => [
          DeviceOperationInProgress(),
          const DeviceOperationSuccess("Device deleted successfully", null),
        ],
        verify: (_) {
          verify(() => mockDeviceRepository.delete(1)).called(1);
        },
      );

      blocTest<DevicesBloc, DevicesState>(
        'should emit failure state when device not found',
        build: () {
          when(() => mockDeviceRepository.delete(any()))
              .thenAnswer((_) async => 0);
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(const DeleteDevice(999)),
        expect: () => [
          DeviceOperationInProgress(),
          const DeviceOperationFailure("Device not found"),
        ],
      );

      blocTest<DevicesBloc, DevicesState>(
        'should emit failure state when deletion fails',
        build: () {
          when(() => mockDeviceRepository.delete(any()))
              .thenThrow(Exception('Database error'));
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(const DeleteDevice(1)),
        expect: () => [
          DeviceOperationInProgress(),
          predicate<DeviceOperationFailure>((state) => 
            state.message.contains('Failed to delete device')
          ),
        ],
      );
    });

    group('SearchDevices', () {
      blocTest<DevicesBloc, DevicesState>(
        'should emit success state with search results',
        build: () {
          when(() => mockDeviceRepository.searchByName(any()))
              .thenAnswer((_) async => [testDevice1]);
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(const SearchDevices('GPS')),
        expect: () => [
          DeviceLoadInProgress(),
          const DeviceLoadSuccess([testDevice1]),
        ],
        verify: (_) {
          verify(() => mockDeviceRepository.searchByName('GPS')).called(1);
        },
      );

      blocTest<DevicesBloc, DevicesState>(
        'should emit empty results when no devices match search',
        build: () {
          when(() => mockDeviceRepository.searchByName(any()))
              .thenAnswer((_) async => []);
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(const SearchDevices('nonexistent')),
        expect: () => [
          DeviceLoadInProgress(),
          const DeviceLoadSuccess([]),
        ],
      );

      blocTest<DevicesBloc, DevicesState>(
        'should emit failure state when search fails',
        build: () {
          when(() => mockDeviceRepository.searchByName(any()))
              .thenThrow(Exception('Database error'));
          return DevicesBloc(mockDeviceRepository);
        },
        act: (bloc) => bloc.add(const SearchDevices('GPS')),
        expect: () => [
          DeviceLoadInProgress(),
          predicate<DeviceOperationFailure>((state) => 
            state.message.contains('Failed to search devices')
          ),
        ],
      );
    });

    group('Events', () {
      test('LoadDevices should be a DevicesEvent', () {
        expect(LoadDevices(), isA<DevicesEvent>());
      });

      test('AddDevice should be a DevicesEvent with correct properties', () {
        const event = AddDevice(testDevice1);
        expect(event, isA<DevicesEvent>());
        expect(event.device, equals(testDevice1));
      });

      test('UpdateDevice should be a DevicesEvent with correct properties', () {
        const event = UpdateDevice(testDevice1);
        expect(event, isA<DevicesEvent>());
        expect(event.device, equals(testDevice1));
      });

      test('DeleteDevice should be a DevicesEvent with correct properties', () {
        const event = DeleteDevice(1);
        expect(event, isA<DevicesEvent>());
        expect(event.deviceId, equals(1));
      });

      test('SearchDevices should be a DevicesEvent with correct properties', () {
        const event = SearchDevices('test');
        expect(event, isA<DevicesEvent>());
        expect(event.query, equals('test'));
      });
    });

    group('States', () {
      test('should support equatable comparison', () {
        const state1 = DeviceLoadSuccess([testDevice1]);
        const state2 = DeviceLoadSuccess([testDevice1]);
        const state3 = DeviceLoadSuccess([testDevice2]);
        
        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
      });

      test('DeviceOperationSuccess should include message and device', () {
        const state = DeviceOperationSuccess("Test message", testDevice1);
        expect(state.message, equals("Test message"));
        expect(state.device, equals(testDevice1));
      });

      test('DeviceOperationFailure should include error message', () {
        const state = DeviceOperationFailure("Error message");
        expect(state.message, equals("Error message"));
      });
    });
  });
}