import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle;

/// A helper class to manage SQLite database operations.
/// Implements the singleton pattern to ensure a single database instance.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  static const _dbName = 'nav-e.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  /// Initialize the database, creating it if it doesn't exist.
  /// Executes the SQL statements from the 'assets/sql/init.sql' file to set up
  /// the initial database schema.
  /// returns `Future<Database>`
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        final initSql = await rootBundle.loadString('assets/sql/init.sql');

        final statements = initSql
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty);

        final batch = db.batch();
        for (final stmt in statements) {
          batch.execute(stmt);
        }
        await batch.commit(noResult: true);
      },
      // Add migrations when you bump _dbVersion
      onUpgrade: (db, oldV, newV) async {
        // TODO: Add logic to handle data migrations.
      },
    );
  }

  /// Insert a new record into the specified table.
  /// [table] The name of the table to insert into.
  /// [values] A map of column names to values to insert.
  /// [conflictAlgorithm] The conflict algorithm to use in case of a conflict.
  /// returns the id of the inserted row.
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  }) async {
    final db = await database;
    return db.insert(table, values, conflictAlgorithm: conflictAlgorithm);
  }

  /// Query records from the specified table.
  /// [table] The name of the table to query.
  /// Optional parameters to filter, sort, and limit the results.
  /// returns a list of maps, where each map represents a row in the result set.
  /// Each map's keys are the column names and the values are the corresponding column values.
  /// returns `Future<List<Map<String, Object?>>>`
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      distinct: distinct ?? false,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Update records in the specified table.
  /// [table] The name of the table to update.
  /// [values] A map of column names to new values.
  /// Optional parameters to filter which rows to update.
  /// [conflictAlgorithm] The conflict algorithm to use in case of a conflict.
  /// returns the number of rows affected.
  /// returns `Future<int>`
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.abort,
  }) async {
    final db = await database;
    return db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// Delete records from the specified table.
  /// [table] The name of the table to delete from.
  /// Optional parameters to filter which rows to delete.
  /// returns the number of rows deleted.
  /// returns `Future<int>`
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Close the database connection.
  /// Should be called when the database is no longer needed to free up resources.
  /// returns nothing.
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
