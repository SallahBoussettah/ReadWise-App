import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reading_companion_app/repositories/repositories.dart';

// Test migration implementations
class TestMigration extends DatabaseMigration {
  final int _version;
  final String _description;
  final String _sql;
  final String? _rollbackSql;

  TestMigration({
    required int version,
    required String description,
    required String sql,
    String? rollbackSql,
  })  : _version = version,
        _description = description,
        _sql = sql,
        _rollbackSql = rollbackSql;

  @override
  int get version => _version;

  @override
  String get description => _description;

  @override
  Future<void> migrate(Database db) async {
    await db.execute(_sql);
  }

  @override
  Future<void> rollback(Database db) async {
    if (_rollbackSql != null) {
      await db.execute(_rollbackSql!);
    } else {
      await super.rollback(db);
    }
  }
}

class FailingMigration extends DatabaseMigration {
  @override
  int get version => 999;

  @override
  String get description => 'Failing migration for testing';

  @override
  Future<void> migrate(Database db) async {
    throw Exception('Migration failed intentionally');
  }
}

void main() {
  late Database database;
  late MigrationManager migrationManager;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );
    migrationManager = MigrationManager();
  });

  tearDown(() async {
    await database.close();
  });

  group('DatabaseMigration', () {
    test('AddColumnMigration should add column to table', () async {
      // Create test table
      await database.execute('CREATE TABLE test_table (id INTEGER PRIMARY KEY)');

      final migration = AddColumnMigration(
        tableName: 'test_table',
        columnName: 'new_column',
        columnDefinition: 'TEXT',
        version: 2,
      );

      expect(migration.version, equals(2));
      expect(migration.description, contains('Add column new_column to test_table'));

      await migration.migrate(database);

      // Verify column was added
      final columns = await database.rawQuery('PRAGMA table_info(test_table)');
      final columnNames = columns.map((col) => col['name'] as String).toSet();
      expect(columnNames, contains('new_column'));
    });

    test('CreateIndexMigration should create index', () async {
      // Create test table
      await database.execute('CREATE TABLE test_table (id INTEGER PRIMARY KEY, name TEXT)');

      final migration = CreateIndexMigration(
        indexName: 'idx_test_name',
        tableName: 'test_table',
        columns: ['name'],
        version: 2,
      );

      expect(migration.version, equals(2));
      expect(migration.description, contains('Create index idx_test_name on test_table'));

      await migration.migrate(database);

      // Verify index was created
      final indexes = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_test_name'"
      );
      expect(indexes.length, equals(1));
    });

    test('CreateIndexMigration should create unique index', () async {
      // Create test table
      await database.execute('CREATE TABLE test_table (id INTEGER PRIMARY KEY, email TEXT)');

      final migration = CreateIndexMigration(
        indexName: 'idx_test_email_unique',
        tableName: 'test_table',
        columns: ['email'],
        unique: true,
        version: 2,
      );

      expect(migration.description, contains('Create unique index'));

      await migration.migrate(database);

      // Verify unique index was created
      final indexes = await database.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type='index' AND name='idx_test_email_unique'"
      );
      expect(indexes.first['sql'], contains('UNIQUE'));
    });

    test('CreateIndexMigration rollback should drop index', () async {
      // Create test table and index
      await database.execute('CREATE TABLE test_table (id INTEGER PRIMARY KEY, name TEXT)');
      await database.execute('CREATE INDEX idx_test_name ON test_table (name)');

      final migration = CreateIndexMigration(
        indexName: 'idx_test_name',
        tableName: 'test_table',
        columns: ['name'],
        version: 2,
      );

      await migration.rollback(database);

      // Verify index was dropped
      final indexes = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_test_name'"
      );
      expect(indexes.length, equals(0));
    });

    test('CustomSqlMigration should execute custom SQL', () async {
      final migration = CustomSqlMigration(
        sql: 'CREATE TABLE custom_table (id INTEGER PRIMARY KEY, data TEXT)',
        rollbackSql: 'DROP TABLE custom_table',
        version: 2,
        description: 'Create custom table',
      );

      expect(migration.version, equals(2));
      expect(migration.description, equals('Create custom table'));

      await migration.migrate(database);

      // Verify table was created
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='custom_table'"
      );
      expect(tables.length, equals(1));

      // Test rollback
      await migration.rollback(database);

      // Verify table was dropped
      final tablesAfterRollback = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='custom_table'"
      );
      expect(tablesAfterRollback.length, equals(0));
    });
  });

  group('MigrationManager', () {
    test('should add and sort migrations by version', () {
      final migration1 = TestMigration(
        version: 3,
        description: 'Migration 3',
        sql: 'SELECT 1',
      );
      final migration2 = TestMigration(
        version: 2,
        description: 'Migration 2',
        sql: 'SELECT 1',
      );

      migrationManager.addMigration(migration1);
      migrationManager.addMigration(migration2);

      final migrations = migrationManager.migrations;
      expect(migrations.length, equals(2));
      expect(migrations[0].version, equals(2));
      expect(migrations[1].version, equals(3));
    });

    test('should execute migrations in correct order', () async {
      // Create test table
      await database.execute('CREATE TABLE migration_log (version INTEGER, description TEXT)');

      final migration2 = TestMigration(
        version: 2,
        description: 'Migration 2',
        sql: "INSERT INTO migration_log VALUES (2, 'Migration 2')",
      );
      final migration3 = TestMigration(
        version: 3,
        description: 'Migration 3',
        sql: "INSERT INTO migration_log VALUES (3, 'Migration 3')",
      );

      migrationManager.addMigration(migration3);
      migrationManager.addMigration(migration2);

      await migrationManager.migrate(database, 1, 3);

      // Verify migrations were executed in order
      final logs = await database.query('migration_log', orderBy: 'version');
      expect(logs.length, equals(2));
      expect(logs[0]['version'], equals(2));
      expect(logs[1]['version'], equals(3));
    });

    test('should only execute migrations within version range', () async {
      // Create test table
      await database.execute('CREATE TABLE migration_log (version INTEGER, description TEXT)');

      final migration2 = TestMigration(
        version: 2,
        description: 'Migration 2',
        sql: "INSERT INTO migration_log VALUES (2, 'Migration 2')",
      );
      final migration3 = TestMigration(
        version: 3,
        description: 'Migration 3',
        sql: "INSERT INTO migration_log VALUES (3, 'Migration 3')",
      );
      final migration4 = TestMigration(
        version: 4,
        description: 'Migration 4',
        sql: "INSERT INTO migration_log VALUES (4, 'Migration 4')",
      );

      migrationManager.addMigration(migration2);
      migrationManager.addMigration(migration3);
      migrationManager.addMigration(migration4);

      // Migrate from version 1 to 3 (should skip migration 4)
      await migrationManager.migrate(database, 1, 3);

      final logs = await database.query('migration_log');
      expect(logs.length, equals(2));
      expect(logs.any((log) => log['version'] == 4), isFalse);
    });

    test('should handle migration failures', () async {
      final failingMigration = FailingMigration();
      migrationManager.addMigration(failingMigration);

      expect(
        () async => await migrationManager.migrate(database, 1, 999),
        throwsA(isA<MigrationException>()),
      );
    });

    test('should rollback migrations in reverse order', () async {
      // Create test table
      await database.execute('CREATE TABLE migration_log (version INTEGER, description TEXT)');

      final migration2 = TestMigration(
        version: 2,
        description: 'Migration 2',
        sql: "INSERT INTO migration_log VALUES (2, 'Migration 2')",
        rollbackSql: "DELETE FROM migration_log WHERE version = 2",
      );
      final migration3 = TestMigration(
        version: 3,
        description: 'Migration 3',
        sql: "INSERT INTO migration_log VALUES (3, 'Migration 3')",
        rollbackSql: "DELETE FROM migration_log WHERE version = 3",
      );

      migrationManager.addMigration(migration2);
      migrationManager.addMigration(migration3);

      // Apply migrations
      await migrationManager.migrate(database, 1, 3);

      // Verify both migrations were applied
      final logsAfterMigration = await database.query('migration_log');
      expect(logsAfterMigration.length, equals(2));

      // Rollback from version 3 to 1
      await migrationManager.rollback(database, 3, 1);

      // Verify all migrations were rolled back
      final logsAfterRollback = await database.query('migration_log');
      expect(logsAfterRollback.length, equals(0));
    });

    test('should check if migration exists for version', () {
      final migration = TestMigration(
        version: 2,
        description: 'Test migration',
        sql: 'SELECT 1',
      );

      expect(migrationManager.hasMigrationForVersion(2), isFalse);

      migrationManager.addMigration(migration);

      expect(migrationManager.hasMigrationForVersion(2), isTrue);
      expect(migrationManager.hasMigrationForVersion(3), isFalse);
    });

    test('should return immutable list of migrations', () {
      final migration = TestMigration(
        version: 2,
        description: 'Test migration',
        sql: 'SELECT 1',
      );

      migrationManager.addMigration(migration);
      final migrations = migrationManager.migrations;

      expect(() => migrations.add(migration), throwsUnsupportedError);
    });
  });

  group('Migration Exceptions', () {
    test('MigrationException should format message correctly', () {
      const exception = MigrationException('Test message');
      expect(exception.toString(), equals('MigrationException: Test message'));
    });

    test('MigrationException should include cause', () {
      final cause = Exception('Root cause');
      final exception = MigrationException('Test message', cause);
      expect(exception.toString(), contains('Test message'));
      expect(exception.toString(), contains('Caused by: Exception: Root cause'));
    });
  });
}