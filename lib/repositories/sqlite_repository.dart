import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'base_repository.dart';
import 'database_helper.dart';

/// Abstract SQLite repository that provides common database operations
abstract class SQLiteRepository<T, ID> implements StreamableRepository<T, ID> {
  final DatabaseHelper _databaseHelper;
  final StreamController<List<T>> _streamController = StreamController<List<T>>.broadcast();

  SQLiteRepository(this._databaseHelper);

  /// Get the table name for this repository
  String get tableName;

  /// Convert a database row to an entity
  T fromMap(Map<String, dynamic> map);

  /// Convert an entity to a database row
  Map<String, dynamic> toMap(T entity);

  /// Get the ID from an entity
  ID getId(T entity);

  /// Get the database instance
  Future<Database> get _database => _databaseHelper.database;

  @override
  Future<List<T>> getAll() async {
    try {
      final db = await _database;
      final List<Map<String, dynamic>> maps = await db.query(tableName);
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw DatabaseOperationException('getAll from $tableName', e);
    }
  }

  @override
  Future<T?> getById(ID id) async {
    try {
      final db = await _database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return fromMap(maps.first);
    } catch (e) {
      throw DatabaseOperationException('getById from $tableName', e);
    }
  }

  @override
  Future<void> insert(T entity) async {
    try {
      final db = await _database;
      final map = toMap(entity);
      
      // Check if entity already exists
      final id = getId(entity);
      if (await exists(id)) {
        throw DuplicateEntityException(tableName, id);
      }
      
      await db.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      
      _notifyListeners();
    } catch (e) {
      if (e is DuplicateEntityException) rethrow;
      throw DatabaseOperationException('insert into $tableName', e);
    }
  }

  @override
  Future<void> update(T entity) async {
    try {
      final db = await _database;
      final map = toMap(entity);
      final id = getId(entity);
      
      final rowsAffected = await db.update(
        tableName,
        map,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (rowsAffected == 0) {
        throw EntityNotFoundException(tableName, id);
      }
      
      _notifyListeners();
    } catch (e) {
      if (e is EntityNotFoundException) rethrow;
      throw DatabaseOperationException('update in $tableName', e);
    }
  }

  @override
  Future<void> delete(ID id) async {
    try {
      final db = await _database;
      
      final rowsAffected = await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (rowsAffected == 0) {
        throw EntityNotFoundException(tableName, id);
      }
      
      _notifyListeners();
    } catch (e) {
      if (e is EntityNotFoundException) rethrow;
      throw DatabaseOperationException('delete from $tableName', e);
    }
  }

  @override
  Future<bool> exists(ID id) async {
    try {
      final db = await _database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      return maps.isNotEmpty;
    } catch (e) {
      throw DatabaseOperationException('exists check in $tableName', e);
    }
  }

  @override
  Future<int> count() async {
    try {
      final db = await _database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseOperationException('count in $tableName', e);
    }
  }

  @override
  Future<void> clear() async {
    try {
      final db = await _database;
      await db.delete(tableName);
      _notifyListeners();
    } catch (e) {
      throw DatabaseOperationException('clear $tableName', e);
    }
  }

  @override
  Stream<List<T>> watchAll() {
    // Initialize stream with current data
    getAll().then((data) {
      if (!_streamController.isClosed) {
        _streamController.add(data);
      }
    }).catchError((error) {
      if (!_streamController.isClosed) {
        _streamController.addError(error);
      }
    });
    
    return _streamController.stream;
  }

  @override
  Stream<T?> watchById(ID id) {
    return watchAll().map((entities) {
      try {
        return entities.firstWhere((entity) => getId(entity) == id);
      } catch (e) {
        return null;
      }
    });
  }

  /// Notify stream listeners of data changes
  void _notifyListeners() {
    getAll().then((data) {
      if (!_streamController.isClosed) {
        _streamController.add(data);
      }
    }).catchError((error) {
      if (!_streamController.isClosed) {
        _streamController.addError(error);
      }
    });
  }

  /// Execute a custom query
  Future<List<Map<String, dynamic>>> query({
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _database;
      return await db.query(
        tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw DatabaseOperationException('custom query in $tableName', e);
    }
  }

  /// Execute a raw query
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    try {
      final db = await _database;
      return await db.rawQuery(sql, arguments);
    } catch (e) {
      throw DatabaseOperationException('raw query', e);
    }
  }

  /// Dispose resources
  void dispose() {
    _streamController.close();
  }
}