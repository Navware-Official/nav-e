import 'dart:ffi';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle;

class DatabaseHelper {
  final dbName = "nav-e.db";

  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        final initSql = await rootBundle.loadString('assets/sql/init.sql');
        final statements = initSql.split(';');

        for (var stmt in statements) {
          final trimmed = stmt.trim();
          if (trimmed.isNotEmpty) {
            await db.execute(trimmed);
          }
        }
      },
    );
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