import 'dart:ffi';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  final databaseName = "nav-e.db";

  Future<Database> initDB() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, databaseName);

    return openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute("CREATE TABLE devices (id INTEGER PRIMARY KEY, name TEXT, model TEXT, remote_id)");
    });
  }

  Future<void> insertRow(String tableName, Map<String, Object?> data) async {
    final db = await initDB();
    await db.insert(
      tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllRowsFrom(String tableName) async {
    final db = await initDB();
    return await db.query(tableName);
  }

  Future<List<Map<String, dynamic>>> getRowById(String tableName, Int id) async {
    final db = await initDB();
    return await db.query(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> updateRowById(String tableName, Int id, Map<String, Object?> data) async {
    final db = await initDB();
    await db.update(
      tableName,
      data,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> deleteRowById(String tableName, Int id) async {
    final db = await initDB();
    await db.delete(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
  }
}