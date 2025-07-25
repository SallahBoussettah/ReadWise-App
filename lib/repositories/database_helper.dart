import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_migration.dart';

/// SQLite database helper class that manages database creation, migrations, and connections
class DatabaseHelper {
  static const String _databaseName = 'reading_companion.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String booksTable = 'books';
  static const String quotesTable = 'quotes';
  static const String readingSessionsTable = 'reading_sessions';
  static const String userStatsTable = 'user_stats';

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  final MigrationManager _migrationManager = MigrationManager();

  /// Get database instance, creating it if it doesn't exist
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    _registerMigrations();
    
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
      onOpen: (db) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await _createBooksTable(db);
    await _createQuotesTable(db);
    await _createReadingSessionsTable(db);
    await _createUserStatsTable(db);
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _migrationManager.migrate(db, oldVersion, newVersion);
  }

  /// Handle database downgrades
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    try {
      await _migrationManager.rollback(db, oldVersion, newVersion);
    } catch (e) {
      // If rollback fails, recreate the database
      await _dropAllTables(db);
      await _onCreate(db, newVersion);
    }
  }

  /// Create books table
  Future<void> _createBooksTable(Database db) async {
    await db.execute('''
      CREATE TABLE $booksTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        cover_url TEXT,
        total_pages INTEGER NOT NULL,
        pages_read INTEGER DEFAULT 0,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        finished_at INTEGER,
        google_books_id TEXT
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_books_status ON $booksTable (status)');
    await db.execute('CREATE INDEX idx_books_created_at ON $booksTable (created_at)');
  }

  /// Create quotes table
  Future<void> _createQuotesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $quotesTable (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        text TEXT NOT NULL,
        page_number INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (book_id) REFERENCES $booksTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_quotes_book_id ON $quotesTable (book_id)');
    await db.execute('CREATE INDEX idx_quotes_created_at ON $quotesTable (created_at)');
  }

  /// Create reading sessions table
  Future<void> _createReadingSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $readingSessionsTable (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        pages_read INTEGER NOT NULL,
        time_spent INTEGER,
        session_date INTEGER NOT NULL,
        FOREIGN KEY (book_id) REFERENCES $booksTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_sessions_book_id ON $readingSessionsTable (book_id)');
    await db.execute('CREATE INDEX idx_sessions_date ON $readingSessionsTable (session_date)');
  }

  /// Create user stats table
  Future<void> _createUserStatsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $userStatsTable (
        id INTEGER PRIMARY KEY,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        total_books_read INTEGER DEFAULT 0,
        total_pages_read INTEGER DEFAULT 0,
        last_reading_date INTEGER
      )
    ''');

    // Insert initial stats record
    await db.insert(userStatsTable, {
      'id': 1,
      'current_streak': 0,
      'longest_streak': 0,
      'total_books_read': 0,
      'total_pages_read': 0,
      'last_reading_date': null,
    });
  }

  /// Register migrations
  void _registerMigrations() {
    // Example migrations for future versions
    // _migrationManager.addMigration(AddColumnMigration(
    //   tableName: booksTable,
    //   columnName: 'isbn',
    //   columnDefinition: 'TEXT',
    //   version: 2,
    //   description: 'Add ISBN column to books table',
    // ));
  }

  /// Drop all tables (used for downgrade)
  Future<void> _dropAllTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS $readingSessionsTable');
    await db.execute('DROP TABLE IF EXISTS $quotesTable');
    await db.execute('DROP TABLE IF EXISTS $booksTable');
    await db.execute('DROP TABLE IF EXISTS $userStatsTable');
  }

  /// Close the database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete the database file (useful for testing)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  /// Check if database exists
  Future<bool> databaseExists() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    return await databaseFactory.databaseExists(path);
  }

  /// Get database path
  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, _databaseName);
  }

  /// Get migration manager for testing purposes
  MigrationManager get migrationManager => _migrationManager;
}