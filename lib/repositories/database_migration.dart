import 'package:sqflite/sqflite.dart';

/// Abstract base class for database migrations
abstract class DatabaseMigration {
  /// The version this migration upgrades to
  int get version;

  /// Description of what this migration does
  String get description;

  /// Execute the migration
  Future<void> migrate(Database db);

  /// Rollback the migration (optional)
  Future<void> rollback(Database db) async {
    throw UnsupportedError('Rollback not implemented for migration to version $version');
  }
}

/// Migration manager that handles database schema changes
class MigrationManager {
  final List<DatabaseMigration> _migrations = [];

  /// Register a migration
  void addMigration(DatabaseMigration migration) {
    _migrations.add(migration);
    _migrations.sort((a, b) => a.version.compareTo(b.version));
  }

  /// Execute migrations from oldVersion to newVersion
  Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    final migrationsToRun = _migrations
        .where((migration) => migration.version > oldVersion && migration.version <= newVersion)
        .toList();

    for (final migration in migrationsToRun) {
      try {
        await migration.migrate(db);
        print('Successfully applied migration to version ${migration.version}: ${migration.description}');
      } catch (e) {
        throw MigrationException(
          'Failed to apply migration to version ${migration.version}: ${migration.description}',
          e,
        );
      }
    }
  }

  /// Rollback migrations from oldVersion to newVersion
  Future<void> rollback(Database db, int oldVersion, int newVersion) async {
    final migrationsToRollback = _migrations
        .where((migration) => migration.version > newVersion && migration.version <= oldVersion)
        .toList()
        .reversed
        .toList();

    for (final migration in migrationsToRollback) {
      try {
        await migration.rollback(db);
        print('Successfully rolled back migration from version ${migration.version}: ${migration.description}');
      } catch (e) {
        throw MigrationException(
          'Failed to rollback migration from version ${migration.version}: ${migration.description}',
          e,
        );
      }
    }
  }

  /// Get all registered migrations
  List<DatabaseMigration> get migrations => List.unmodifiable(_migrations);

  /// Check if a migration exists for a specific version
  bool hasMigrationForVersion(int version) {
    return _migrations.any((migration) => migration.version == version);
  }
}

/// Exception thrown when a migration fails
class MigrationException implements Exception {
  final String message;
  final dynamic cause;

  const MigrationException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'MigrationException: $message\nCaused by: $cause';
    }
    return 'MigrationException: $message';
  }
}

/// Example migration for adding a new column
class AddColumnMigration extends DatabaseMigration {
  final String tableName;
  final String columnName;
  final String columnDefinition;
  final int _version;
  final String _description;

  AddColumnMigration({
    required this.tableName,
    required this.columnName,
    required this.columnDefinition,
    required int version,
    String? description,
  })  : _version = version,
        _description = description ?? 'Add column $columnName to $tableName';

  @override
  int get version => _version;

  @override
  String get description => _description;

  @override
  Future<void> migrate(Database db) async {
    await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition');
  }

  @override
  Future<void> rollback(Database db) async {
    // SQLite doesn't support DROP COLUMN, so we'd need to recreate the table
    throw UnsupportedError('Cannot rollback ADD COLUMN migration in SQLite');
  }
}

/// Example migration for creating an index
class CreateIndexMigration extends DatabaseMigration {
  final String indexName;
  final String tableName;
  final List<String> columns;
  final bool unique;
  final int _version;
  final String _description;

  CreateIndexMigration({
    required this.indexName,
    required this.tableName,
    required this.columns,
    this.unique = false,
    required int version,
    String? description,
  })  : _version = version,
        _description = description ?? 'Create ${unique ? 'unique ' : ''}index $indexName on $tableName';

  @override
  int get version => _version;

  @override
  String get description => _description;

  @override
  Future<void> migrate(Database db) async {
    final uniqueKeyword = unique ? 'UNIQUE ' : '';
    final columnList = columns.join(', ');
    await db.execute('CREATE ${uniqueKeyword}INDEX $indexName ON $tableName ($columnList)');
  }

  @override
  Future<void> rollback(Database db) async {
    await db.execute('DROP INDEX IF EXISTS $indexName');
  }
}

/// Example migration for executing custom SQL
class CustomSqlMigration extends DatabaseMigration {
  final String sql;
  final String? rollbackSql;
  final int _version;
  final String _description;

  CustomSqlMigration({
    required this.sql,
    this.rollbackSql,
    required int version,
    required String description,
  })  : _version = version,
        _description = description;

  @override
  int get version => _version;

  @override
  String get description => _description;

  @override
  Future<void> migrate(Database db) async {
    await db.execute(sql);
  }

  @override
  Future<void> rollback(Database db) async {
    if (rollbackSql != null) {
      await db.execute(rollbackSql!);
    } else {
      super.rollback(db);
    }
  }
}