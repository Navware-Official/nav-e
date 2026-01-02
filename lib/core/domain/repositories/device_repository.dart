import 'package:nav_e/core/domain/entities/device.dart';

abstract class IDeviceRepository {
  /// Get all devices from the database
  Future<List<Device>> getAll();

  /// Get a device by its ID
  Future<Device?> getById(int id);

  /// Get a device by its remote ID (e.g., Bluetooth MAC address)
  Future<Device?> getByRemoteId(String remoteId);

  /// Insert a new device into the database
  /// Returns the ID of the inserted device
  Future<int> insert(Device device);

  /// Update an existing device in the database
  /// Returns the number of rows affected
  Future<int> update(Device device);

  /// Delete a device by its ID
  /// Returns the number of rows affected
  Future<int> delete(int id);

  /// Check if a device with the given remote ID exists
  Future<bool> existsByRemoteId(String remoteId);

  /// Get devices by name (partial match, case-insensitive)
  Future<List<Device>> searchByName(String name);
}
