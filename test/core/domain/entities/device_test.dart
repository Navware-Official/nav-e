import 'package:flutter_test/flutter_test.dart';
import 'package:nav_e/core/domain/entities/device.dart';

void main() {
  group('Device Entity', () {
    group('constructor', () {
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
    });

    group('copyWith', () {
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

      test('should preserve original values when not specified', () {
        const original = Device(
          id: 1,
          name: 'Original',
          model: 'Model A',
          remoteId: 'ORIGINAL_ID',
        );
        
        final updated = original.copyWith(name: 'Updated');
        
        expect(updated.id, equals(1));
        expect(updated.name, equals('Updated'));
        expect(updated.model, equals('Model A'));
        expect(updated.remoteId, equals('ORIGINAL_ID'));
      });
    });

    group('serialization', () {
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

      test('should include id when not null in toMap', () {
        const device = Device(id: 1, name: 'Test');
        final map = device.toMap();
        
        expect(map['id'], equals(1));
        expect(map['name'], equals('Test'));
      });

      test('should handle null values in fromMap', () {
        final map = {
          'id': 1,
          'name': 'Test Device',
          'model': null,
          'remote_id': null,
        };
        
        final device = Device.fromMap(map);
        
        expect(device.id, equals(1));
        expect(device.name, equals('Test Device'));
        expect(device.model, isNull);
        expect(device.remoteId, isNull);
      });

      test('should handle missing optional fields in fromMap', () {
        final map = {
          'id': 1,
          'name': 'Test Device',
        };
        
        final device = Device.fromMap(map);
        
        expect(device.id, equals(1));
        expect(device.name, equals('Test Device'));
        expect(device.model, isNull);
        expect(device.remoteId, isNull);
      });
    });

    group('equatable', () {
      test('should support equatable comparison', () {
        const device1 = Device(id: 1, name: 'Test');
        const device2 = Device(id: 1, name: 'Test');
        const device3 = Device(id: 2, name: 'Test');
        
        expect(device1, equals(device2));
        expect(device1, isNot(equals(device3)));
      });

      test('should consider all properties in equality', () {
        const device1 = Device(
          id: 1,
          name: 'Test',
          model: 'Model A',
          remoteId: 'ID1',
        );
        const device2 = Device(
          id: 1,
          name: 'Test',
          model: 'Model A',
          remoteId: 'ID1',
        );
        const device3 = Device(
          id: 1,
          name: 'Test',
          model: 'Model B',
          remoteId: 'ID1',
        );
        
        expect(device1, equals(device2));
        expect(device1, isNot(equals(device3)));
      });
    });

    group('toString', () {
      test('should provide readable string representation', () {
        const device = Device(
          id: 1,
          name: 'Test Device',
          model: 'Test Model',
          remoteId: 'test_id',
        );
        
        final string = device.toString();
        
        expect(string, contains('Device'));
        expect(string, contains('id: 1'));
        expect(string, contains('name: Test Device'));
        expect(string, contains('model: Test Model'));
        expect(string, contains('remoteId: test_id'));
      });
    });
  });
}