import 'package:nav_e/core/domain/entities/device.dart';
import 'package:nav_e/core/domain/repositories/device_repository.dart';
import 'package:sqflite/sqflite.dart';

class DeviceRepositoryImpl implements IDeviceRepository {
  final Database db;
  static const String _tableName = 'devices';

  DeviceRepositoryImpl(this.db);

  @override
  Future<List<Device>> getAll() async {
    final result = await db.query(_tableName, orderBy: 'name ASC');
    return result.map((row) => Device.fromMap(row)).toList();
  }

  @override
  Future<Device?> getById(int id) async {
    final result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return null;
    return Device.fromMap(result.first);
  }

  @override
  Future<Device?> getByRemoteId(String remoteId) async {
    final result = await db.query(
      _tableName,
      where: 'remote_id = ?',
      whereArgs: [remoteId],
    );
    
    if (result.isEmpty) return null;
    return Device.fromMap(result.first);
  }

  @override
  Future<int> insert(Device device) async {
    // Don't include id in insert if it's null (auto-increment)
    final map = device.toMap();
    map.remove('id');
    
    return await db.insert(_tableName, map);
  }

  @override
  Future<int> update(Device device) async {
    if (device.id == null) {
      throw ArgumentError('Device ID cannot be null for update operation');
    }
    
    final map = device.toMap();
    map.remove('id'); // Don't update the ID column
    
    return await db.update(
      _tableName,
      map,
      where: 'id = ?',
      whereArgs: [device.id],
    );
  }

  @override
  Future<int> delete(int id) async {
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<bool> existsByRemoteId(String remoteId) async {
    final result = await db.query(
      _tableName,
      columns: ['id'],
      where: 'remote_id = ?',
      whereArgs: [remoteId],
      limit: 1,
    );
    
    return result.isNotEmpty;
  }

  @override
  Future<List<Device>> searchByName(String name) async {
    final result = await db.query(
      _tableName,
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
      orderBy: 'name ASC',
    );
    
    return result.map((row) => Device.fromMap(row)).toList();
  }
}