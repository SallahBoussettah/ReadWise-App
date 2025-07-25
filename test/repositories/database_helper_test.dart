import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reading_companion_app/repositories/repositories.dart';

void main() {
  late DatabaseHelper databaseHelper;

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    databaseHelper = DatabaseHelper.instance;
  });

  tearDown(() async {
    // Clean up database after each test
    await databaseHelper.deleteDatabase();
  });

  group('DatabaseHelper', () {
    test('should create database with correct version', () async {
      final db = await databaseHelper.database;
      expect(db.isOpen, isTrue);
      expect(await db.getVersion(), equals(1));
    });

    test('should create all required tables', () async {
      final db = await databaseHelper.database;
      
      // Check if all tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      final tableNames = tables.map((table) => table['name'] as String).toSet();
      
      expect(tableNames, contains(DatabaseHelper.booksTable));
      expect(tableNames, contains(DatabaseHelper.quotesTable));
      expect(tableNames, contains(DatabaseHelper.readingSessionsTable));
      expect(tableNames, contains(DatabaseHelper.userStatsTable));
    });

    test('should create books table with correct schema', () async {
      final db = await databaseHelper.database;
      
      final columns = await db.rawQuery('PRAGMA table_info(${DatabaseHelper.booksTable})');
      final columnNames = columns.map((col) => col['name'] as String).toSet();
      
      expect(columnNames, contains('id'));
      expect(columnNames, contains('title'));
      expect(columnNames, contains('author'));
      expect(columnNames, contains('cover_url'));
      expect(columnNames, contains('total_pages'));
      expect(columnNames, contains('pages_read'));
      expect(columnNames, contains('status'));
      expect(columnNames, contains('created_at'));
      expect(columnNames, contains('finished_at'));
      expect(columnNames, contains('google_books_id'));
    });

    test('should create quotes table with correct schema', () async {
      final db = await databaseHelper.database;
      
      final columns = await db.rawQuery('PRAGMA table_info(${DatabaseHelper.quotesTable})');
      final columnNames = columns.map((col) => col['name'] as String).toSet();
      
      expect(columnNames, contains('id'));
      expect(columnNames, contains('book_id'));
      expect(columnNames, contains('text'));
      expect(columnNames, contains('page_number'));
      expect(columnNames, contains('created_at'));
    });

    test('should create reading_sessions table with correct schema', () async {
      final db = await databaseHelper.database;
      
      final columns = await db.rawQuery('PRAGMA table_info(${DatabaseHelper.readingSessionsTable})');
      final columnNames = columns.map((col) => col['name'] as String).toSet();
      
      expect(columnNames, contains('id'));
      expect(columnNames, contains('book_id'));
      expect(columnNames, contains('pages_read'));
      expect(columnNames, contains('time_spent'));
      expect(columnNames, contains('session_date'));
    });

    test('should create user_stats table with correct schema', () async {
      final db = await databaseHelper.database;
      
      final columns = await db.rawQuery('PRAGMA table_info(${DatabaseHelper.userStatsTable})');
      final columnNames = columns.map((col) => col['name'] as String).toSet();
      
      expect(columnNames, contains('id'));
      expect(columnNames, contains('current_streak'));
      expect(columnNames, contains('longest_streak'));
      expect(columnNames, contains('total_books_read'));
      expect(columnNames, contains('total_pages_read'));
      expect(columnNames, contains('last_reading_date'));
    });

    test('should create indexes for better performance', () async {
      final db = await databaseHelper.database;
      
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'"
      );
      
      final indexNames = indexes.map((index) => index['name'] as String).toSet();
      
      expect(indexNames, contains('idx_books_status'));
      expect(indexNames, contains('idx_books_created_at'));
      expect(indexNames, contains('idx_quotes_book_id'));
      expect(indexNames, contains('idx_quotes_created_at'));
      expect(indexNames, contains('idx_sessions_book_id'));
      expect(indexNames, contains('idx_sessions_date'));
    });

    test('should initialize user_stats table with default values', () async {
      final db = await databaseHelper.database;
      
      final result = await db.query(DatabaseHelper.userStatsTable);
      expect(result.length, equals(1));
      
      final stats = result.first;
      expect(stats['id'], equals(1));
      expect(stats['current_streak'], equals(0));
      expect(stats['longest_streak'], equals(0));
      expect(stats['total_books_read'], equals(0));
      expect(stats['total_pages_read'], equals(0));
      expect(stats['last_reading_date'], isNull);
    });

    test('should enforce foreign key constraints', () async {
      final db = await databaseHelper.database;
      
      // Enable foreign key constraints
      await db.execute('PRAGMA foreign_keys = ON');
      
      // Try to insert a quote with non-existent book_id
      expect(
        () async => await db.insert(DatabaseHelper.quotesTable, {
          'id': 'quote1',
          'book_id': 'non_existent_book',
          'text': 'Test quote',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('should handle database close and reopen', () async {
      // Open database
      final db1 = await databaseHelper.database;
      expect(db1.isOpen, isTrue);
      
      // Close database
      await databaseHelper.close();
      
      // Reopen database
      final db2 = await databaseHelper.database;
      expect(db2.isOpen, isTrue);
      
      // Should be able to query tables
      final tables = await db2.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      expect(tables.isNotEmpty, isTrue);
    });

    test('should check if database exists', () async {
      // Initially database doesn't exist
      expect(await databaseHelper.databaseExists(), isFalse);
      
      // After accessing database, it should exist
      await databaseHelper.database;
      expect(await databaseHelper.databaseExists(), isTrue);
      
      // After deletion, it shouldn't exist
      await databaseHelper.deleteDatabase();
      expect(await databaseHelper.databaseExists(), isFalse);
    });

    test('should return correct database path', () async {
      final path = await databaseHelper.getDatabasePath();
      expect(path, contains('reading_companion.db'));
    });

    test('should provide access to migration manager', () {
      final migrationManager = databaseHelper.migrationManager;
      expect(migrationManager, isA<MigrationManager>());
    });
  });
}