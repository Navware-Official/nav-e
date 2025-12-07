import 'dart:convert';
import 'package:nav_e/core/domain/entities/device.dart';
import 'package:nav_e/core/domain/repositories/device_repository.dart';
import 'package:nav_e/bridge/api_v2.dart' as api;

/// Rust-backed device repository
/// All persistence logic is handled in Rust, this is a thin wrapper
class DeviceRepositoryRust implements IDeviceRepository {
  @override
  Future<List<Device>> getAll() async {
    final json = api.getAllDevices();
    final List<dynamic> data = jsonDecode(json);
    
    return data.map((item) => _fromRustJson(item)).toList();
  }

  @override
  Future<Device?> getById(int id) async {
    final json = api.getDeviceById(id: id);
    if (json == 'null') return null;
    
    final data = jsonDecode(json);
    return _fromRustJson(data);
  }

  @override
  Future<Device?> getByRemoteId(String remoteId) async {
    final json = api.getDeviceByRemoteId(remoteId: remoteId);
    if (json == 'null') return null;
    
    final data = jsonDecode(json);
    return _fromRustJson(data);
  }

  @override
  Future<int> insert(Device device) async {
    final deviceJson = jsonEncode(_toRustJson(device));
    final id = api.saveDevice(deviceJson: deviceJson);
    return id;
  }

  @override
  Future<int> update(Device device) async {
    if (device.id == null) {
      throw ArgumentError('Device ID cannot be null for update operation');
    }
    
    final deviceJson = jsonEncode(_toRustJson(device));
    api.updateDevice(id: device.id!, deviceJson: deviceJson);
    return 1; // Assume success
  }

  @override
  Future<int> delete(int id) async {
    api.deleteDevice(id: id);
    return 1; // Assume success
  }

  @override
  Future<bool> existsByRemoteId(String remoteId) async {
    return api.deviceExistsByRemoteId(remoteId: remoteId);
  }

  @override
  Future<List<Device>> searchByName(String name) async {
    // For now, get all and filter in Dart
    // TODO: Add Rust API for search if needed for performance
    final all = await getAll();
    final lowerName = name.toLowerCase();
    return all.where((d) => d.name.toLowerCase().contains(lowerName)).toList();
  }

  Device _fromRustJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int?,
      remoteId: json['remote_id'] as String,
      name: json['name'] as String,
      model: json['device_type'] as String?, // Map device_type to model
    );
  }

  Map<String, dynamic> _toRustJson(Device device) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': device.id,
      'remote_id': device.remoteId,
      'name': device.name,
      'device_type': device.model ?? 'Unknown',
      'connection_type': 'bluetooth', // Default to bluetooth
      'paired': true, // Default to paired
      'last_connected': now,
      'firmware_version': null,
      'battery_level': null,
      'created_at': now,
      'updated_at': now,
    };
  }
}
