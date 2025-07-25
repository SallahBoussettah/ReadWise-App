import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/book.dart';
import '../models/book_status.dart';
import 'book_repository.dart';
import 'database_helper.dart';
import 'base_repository.dart';

/// SQLite implementation of BookRepository
class SqliteBookRepository implements BookRepository {
  final DatabaseHelper _databaseHelper;
  final StreamController<List<Book>> _booksStreamController = StreamController<List<Book>>.broadcast();
  final Map<String, StreamController<Book?>> _bookStreamControllers = {};

  SqliteBookRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<List<Book>> getAll() async {
    return getAllBooks();
  }

  @override
  Future<List<Book>> getAllBooks() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.booksTable,
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => _mapToBook(map)).toList();
    } catch (e) {
      // If database is closed, return empty list instead of throwing
      if (e.toString().contains('database is closed') || e.toString().contains('DatabaseException')) {
        return <Book>[];
      }
      throw DatabaseOperationException('Failed to get all books', e);
    }
  }

  @override
  Future<List<Book>> getBooksByStatus(BookStatus status) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.booksTable,
        where: 'status = ?',
        whereArgs: [status.value],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => _mapToBook(map)).toList();
    } catch (e) {
      throw DatabaseOperationException('Failed to get books by status', e);
    }
  }

  @override
  Future<Book?> getById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.booksTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return _mapToBook(maps.first);
    } catch (e) {
      throw DatabaseOperationException('Failed to get book by id', e);
    }
  }

  @override
  Future<void> addBook(Book book) async {
    try {
      final db = await _databaseHelper.database;
      
      // Check if book already exists
      final existing = await getById(book.id);
      if (existing != null) {
        throw DuplicateEntityException('Book', book.id);
      }

      await db.insert(
        DatabaseHelper.booksTable,
        _bookToMap(book),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      await _notifyBooksChanged();
      await _notifyBookChanged(book.id, book);
    } catch (e) {
      if (e is DuplicateEntityException) rethrow;
      throw DatabaseOperationException('Failed to add book', e);
    }
  }

  @override
  Future<void> insert(Book entity) async {
    return addBook(entity);
  }

  @override
  Future<void> updateBook(Book book) async {
    try {
      final db = await _databaseHelper.database;
      
      final rowsAffected = await db.update(
        DatabaseHelper.booksTable,
        _bookToMap(book),
        where: 'id = ?',
        whereArgs: [book.id],
      );

      if (rowsAffected == 0) {
        throw EntityNotFoundException('Book', book.id);
      }

      await _notifyBooksChanged();
      await _notifyBookChanged(book.id, book);
    } catch (e) {
      if (e is EntityNotFoundException) rethrow;
      throw DatabaseOperationException('Failed to update book', e);
    }
  }

  @override
  Future<void> update(Book entity) async {
    return updateBook(entity);
  }

  @override
  Future<void> deleteBook(String id) async {
    try {
      final db = await _databaseHelper.database;
      
      final rowsAffected = await db.delete(
        DatabaseHelper.booksTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw EntityNotFoundException('Book', id);
      }

      await _notifyBooksChanged();
      await _notifyBookChanged(id, null);
    } catch (e) {
      if (e is EntityNotFoundException) rethrow;
      throw DatabaseOperationException('Failed to delete book', e);
    }
  }

  @override
  Future<void> delete(String id) async {
    return deleteBook(id);
  }

  @override
  Future<bool> exists(String id) async {
    try {
      final book = await getById(id);
      return book != null;
    } catch (e) {
      throw DatabaseOperationException('Failed to check if book exists', e);
    }
  }

  @override
  Future<int> count() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.booksTable}');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseOperationException('Failed to count books', e);
    }
  }

  @override
  Future<void> clear() async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(DatabaseHelper.booksTable);
      await _notifyBooksChanged();
      
      // Notify all individual book streams that their books are gone
      for (final controller in _bookStreamControllers.values) {
        controller.add(null);
      }
    } catch (e) {
      throw DatabaseOperationException('Failed to clear books', e);
    }
  }

  @override
  Stream<List<Book>> watchAll() {
    // Initialize stream with current data if not already done
    if (!_booksStreamController.hasListener) {
      _initializeBooksStream();
    }
    return _booksStreamController.stream;
  }

  @override
  Stream<List<Book>> watchBooksByStatus(BookStatus status) {
    return watchAll().map((books) => books.where((book) => book.status == status).toList());
  }

  @override
  Stream<Book?> watchById(String id) {
    if (!_bookStreamControllers.containsKey(id)) {
      _bookStreamControllers[id] = StreamController<Book?>.broadcast();
      // Initialize with current data
      _initializeBookStream(id);
    }
    return _bookStreamControllers[id]!.stream;
  }

  /// Convert database map to Book object
  Book _mapToBook(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      coverUrl: map['cover_url'] as String?,
      totalPages: map['total_pages'] as int,
      pagesRead: map['pages_read'] as int,
      status: BookStatus.fromString(map['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      finishedAt: map['finished_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['finished_at'] as int)
          : null,
      quotes: const [], // Quotes will be loaded separately when needed
    );
  }

  /// Convert Book object to database map
  Map<String, dynamic> _bookToMap(Book book) {
    return {
      'id': book.id,
      'title': book.title,
      'author': book.author,
      'cover_url': book.coverUrl,
      'total_pages': book.totalPages,
      'pages_read': book.pagesRead,
      'status': book.status.value,
      'created_at': book.createdAt.millisecondsSinceEpoch,
      'finished_at': book.finishedAt?.millisecondsSinceEpoch,
    };
  }

  /// Initialize books stream with current data
  Future<void> _initializeBooksStream() async {
    try {
      if (!_booksStreamController.isClosed) {
        final books = await getAllBooks();
        _booksStreamController.add(books);
      }
    } catch (e) {
      if (!_booksStreamController.isClosed) {
        _booksStreamController.addError(e);
      }
    }
  }

  /// Initialize individual book stream with current data
  Future<void> _initializeBookStream(String id) async {
    try {
      final controller = _bookStreamControllers[id];
      if (controller != null && !controller.isClosed) {
        final book = await getById(id);
        controller.add(book);
      }
    } catch (e) {
      final controller = _bookStreamControllers[id];
      if (controller != null && !controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  /// Notify all books stream listeners of changes
  Future<void> _notifyBooksChanged() async {
    try {
      if (!_booksStreamController.isClosed) {
        final books = await getAllBooks();
        _booksStreamController.add(books);
      }
    } catch (e) {
      if (!_booksStreamController.isClosed) {
        _booksStreamController.addError(e);
      }
    }
  }

  /// Notify individual book stream listeners of changes
  Future<void> _notifyBookChanged(String id, Book? book) async {
    final controller = _bookStreamControllers[id];
    if (controller != null && !controller.isClosed) {
      controller.add(book);
    }
  }

  /// Dispose of all stream controllers
  void dispose() {
    _booksStreamController.close();
    for (final controller in _bookStreamControllers.values) {
      controller.close();
    }
    _bookStreamControllers.clear();
  }
}