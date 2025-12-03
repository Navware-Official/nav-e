import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nav_e/core/domain/entities/device.dart';
import 'package:nav_e/features/device_management/data/device_repository_impl.dart';

void main() {
  group('DeviceRepositoryImpl', () {
    late Database database;
    late DeviceRepositoryImpl repository;

    setUp(() async {
      // Initialize sqflite for tests
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      // Create in-memory database for tests
      database = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE devices (
              id INTEGER PRIMARY KEY,
              name TEXT,
              model TEXT,
              remote_id TEXT
            )
          ''');
        },
      );
      
      repository = DeviceRepositoryImpl(database);
    });

    tearDown(() async {
      await database.close();
    });

    group('Device entity', () {
      test('should create device with required properties', () {
        const device = Device(name: 'Test Device');
        
        expect(device.name, equals('Test Device'));
        expect(device.id, isNull);
        expect(device.model, isNull);
        expect(device.remoteId, isNull);
      });

      test('should create device with all properties', () {
        const device = Device(
          id: 1,
          name: 'GPS Navigator',
          model: 'NavTech 3000',
          remoteId: 'AA:BB:CC:DD:EE:FF',
        );
        
        expect(device.id, equals(1));
        expect(device.name, equals('GPS Navigator'));
        expect(device.model, equals('NavTech 3000'));
        expect(device.remoteId, equals('AA:BB:CC:DD:EE:FF'));
      });

      test('should support copyWith', () {
        const original = Device(
          id: 1,
          name: 'Original',
          model: 'Model A',
        );
        
        final updated = original.copyWith(
          name: 'Updated',
          remoteId: 'NEW_ID',
        );
        
        expect(updated.id, equals(1));
        expect(updated.name, equals('Updated'));
        expect(updated.model, equals('Model A'));
        expect(updated.remoteId, equals('NEW_ID'));
      });

      test('should convert to and from map correctly', () {
        const device = Device(
          id: 1,
          name: 'Test Device',
          model: 'Test Model',
          remoteId: 'test_id',
        );
        
        final map = device.toMap();
        final recreated = Device.fromMap(map);
        
        expect(recreated, equals(device));
      });

      test('should exclude null id from toMap', () {
        const device = Device(name: 'Test');
        final map = device.toMap();
        
        expect(map.containsKey('id'), isFalse);
        expect(map['name'], equals('Test'));
      });

      test('should support equatable comparison', () {
        const device1 = Device(id: 1, name: 'Test');
        const device2 = Device(id: 1, name: 'Test');
        const device3 = Device(id: 2, name: 'Test');
        
        expect(device1, equals(device2));
        expect(device1, isNot(equals(device3)));
      });
    });

    group('getAll', () {
      test('should return empty list when no devices exist', () async {
        final devices = await repository.getAll();
        expect(devices, isEmpty);
      });

      test('should return all devices ordered by name', () async {
        // Insert test devices
        await database.insert('devices', {
          'name': 'Zebra Device',
          'model': 'Model Z',
        });
        await database.insert('devices', {
          'name': 'Alpha Device',
          'model': 'Model A',
        });
        
        final devices = await repository.getAll();
        
        expect(devices, hasLength(2));
        expect(devices[0].name, equals('Alpha Device'));
        expect(devices[1].name, equals('Zebra Device'));
      });
    });

    group('getById', () {
      test('should return null when device does not exist', () async {
        final device = await repository.getById(999);
        expect(device, isNull);
      });

      test('should return device when it exists', () async {
        // Insert test device
        final id = await database.insert('devices', {
          'name': 'Test Device',
          'model': 'Test Model',
          'remote_id': 'test_remote_id',
        });
        
        final device = await repository.getById(id);
        
        expect(device, isNotNull);
        expect(device!.id, equals(id));
        expect(device.name, equals('Test Device'));
        expect(device.model, equals('Test Model'));
        expect(device.remoteId, equals('test_remote_id'));
      });
    });

    group('getByRemoteId', () {
      test('should return null when device with remote ID does not exist', () async {
        final device = await repository.getByRemoteId('nonexistent');
        expect(device, isNull);
      });

      test('should return device when remote ID exists', () async {
        await database.insert('devices', {
          'name': 'Bluetooth Device',
          'remote_id': 'AA:BB:CC:DD:EE:FF',
        });
        
        final device = await repository.getByRemoteId('AA:BB:CC:DD:EE:FF');
        
        expect(device, isNotNull);
        expect(device!.name, equals('Bluetooth Device'));
        expect(device.remoteId, equals('AA:BB:CC:DD:EE:FF'));
      });
    });

    group('insert', () {
      test('should insert device and return generated ID', () async {
        const device = Device(
          name: 'New Device',
          model: 'New Model',
          remoteId: 'new_remote_id',
        );
        
        final id = await repository.insert(device);
        
        expect(id, isA<int>());
        expect(id, greaterThan(0));
        
        // Verify insertion
        final inserted = await repository.getById(id);
        expect(inserted, isNotNull);
        expect(inserted!.name, equals('New Device'));
        expect(inserted.model, equals('New Model'));
        expect(inserted.remoteId, equals('new_remote_id'));
      });

      test('should insert device without optional fields', () async {
        const device = Device(name: 'Simple Device');
        
        final id = await repository.insert(device);
        final inserted = await repository.getById(id);
        
        expect(inserted, isNotNull);
        expect(inserted!.name, equals('Simple Device'));
        expect(inserted.model, isNull);
        expect(inserted.remoteId, isNull);
      });
    });

    group('update', () {
      test('should throw error when updating device without ID', () async {
        const device = Device(name: 'No ID Device');
        
        expect(
          () => repository.update(device),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should update existing device', () async {
        // Insert device
        final id = await database.insert('devices', {
          'name': 'Original Name',
          'model': 'Original Model',
        });
        
        // Update device
        final updatedDevice = Device(
          id: id,
          name: 'Updated Name',
          model: 'Updated Model',
          remoteId: 'new_remote_id',
        );
        
        final rowsAffected = await repository.update(updatedDevice);
        
        expect(rowsAffected, equals(1));
        
        // Verify update
        final retrieved = await repository.getById(id);
        expect(retrieved!.name, equals('Updated Name'));
        expect(retrieved.model, equals('Updated Model'));
        expect(retrieved.remoteId, equals('new_remote_id'));
      });

      test('should return 0 when updating non-existent device', () async {
        const device = Device(
          id: 999,
          name: 'Non-existent',
        );
        
        final rowsAffected = await repository.update(device);
        expect(rowsAffected, equals(0));
      });
    });

    group('delete', () {
      test('should delete existing device', () async {
        // Insert device
        final id = await database.insert('devices', {
          'name': 'Device to Delete',
        });
        
        final rowsAffected = await repository.delete(id);
        
        expect(rowsAffected, equals(1));
        
        // Verify deletion
        final device = await repository.getById(id);
        expect(device, isNull);
      });

      test('should return 0 when deleting non-existent device', () async {
        final rowsAffected = await repository.delete(999);
        expect(rowsAffected, equals(0));
      });
    });

    group('existsByRemoteId', () {
      test('should return false when remote ID does not exist', () async {
        final exists = await repository.existsByRemoteId('nonexistent');
        expect(exists, isFalse);
      });

      test('should return true when remote ID exists', () async {
        await database.insert('devices', {
          'name': 'Test Device',
          'remote_id': 'existing_id',
        });
        
        final exists = await repository.existsByRemoteId('existing_id');
        expect(exists, isTrue);
      });
    });

    group('searchByName', () {
      test('should return empty list when no matches found', () async {
        await database.insert('devices', {'name': 'GPS Navigator'});
        
        final results = await repository.searchByName('Bluetooth');
        expect(results, isEmpty);
      });

      test('should find devices with partial name match', () async {
        await database.insert('devices', {'name': 'GPS Navigator Pro'});
        await database.insert('devices', {'name': 'GPS Tracker'});
        await database.insert('devices', {'name': 'Bluetooth Speaker'});
        
        final results = await repository.searchByName('GPS');
        
        expect(results, hasLength(2));
        expect(results.any((d) => d.name == 'GPS Navigator Pro'), isTrue);
        expect(results.any((d) => d.name == 'GPS Tracker'), isTrue);
      });

      test('should be case insensitive', () async {
        await database.insert('devices', {'name': 'GPS Navigator'});
        
        final results = await repository.searchByName('gps');
        expect(results, hasLength(1));
        expect(results.first.name, equals('GPS Navigator'));
      });

      test('should return results ordered by name', () async {
        await database.insert('devices', {'name': 'Zebra GPS'});
        await database.insert('devices', {'name': 'Alpha GPS'});
        
        final results = await repository.searchByName('GPS');
        
        expect(results, hasLength(2));
        expect(results[0].name, equals('Alpha GPS'));
        expect(results[1].name, equals('Zebra GPS'));
      });
    });

    group('error handling', () {
      test('should handle database errors gracefully', () async {
        // Close database to simulate error
        await database.close();
        
        expect(
          () => repository.getAll(),
          throwsA(isA<DatabaseException>()),
        );
      });
    });
  });
}