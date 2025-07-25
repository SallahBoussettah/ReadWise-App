import 'dart:async';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../models/quote.dart';
import 'base_repository.dart';
import 'database_helper.dart';
import 'quote_repository.dart';

/// SQLite implementation of QuoteRepository
class SqliteQuoteRepository implements QuoteRepository {
  final DatabaseHelper _databaseHelper;
  final StreamController<List<Quote>> _quotesController = StreamController<List<Quote>>.broadcast();
  final Map<String, StreamController<List<Quote>>> _bookQuotesControllers = {};
  final Map<String, StreamController<Quote?>> _quoteControllers = {};

  SqliteQuoteRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<List<Quote>> getAll() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.quotesTable,
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => _mapToQuote(map)).toList();
    } catch (e) {
      throw DatabaseOperationException('Failed to get all quotes', e);
    }
  }

  @override
  Future<List<Quote>> getAllQuotes() => getAll();

  @override
  Future<List<Quote>> getQuotesByBook(String bookId) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.quotesTable,
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => _mapToQuote(map)).toList();
    } catch (e) {
      throw DatabaseOperationException('Failed to get quotes by book', e);
    }
  }

  @override
  Future<Quote?> getById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.quotesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return _mapToQuote(maps.first);
    } catch (e) {
      throw DatabaseOperationException('Failed to get quote by id', e);
    }
  }

  @override
  Future<Quote?> getRandomQuote() async {
    try {
      final db = await _databaseHelper.database;
      
      // First, get the count of quotes
      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM ${DatabaseHelper.quotesTable}');
      final count = countResult.first['count'] as int;
      
      if (count == 0) {
        return null;
      }

      // Generate a random offset
      final random = Random();
      final offset = random.nextInt(count);

      // Get a random quote using LIMIT and OFFSET
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.quotesTable,
        limit: 1,
        offset: offset,
      );

      if (maps.isEmpty) {
        return null;
      }

      return _mapToQuote(maps.first);
    } catch (e) {
      throw DatabaseOperationException('Failed to get random quote', e);
    }
  }

  @override
  Future<void> insert(Quote entity) async {
    await addQuote(entity);
  }

  @override
  Future<void> addQuote(Quote quote) async {
    try {
      final db = await _databaseHelper.database;
      
      // Check if quote already exists
      if (await exists(quote.id)) {
        throw DuplicateEntityException('Quote', quote.id);
      }

      await db.insert(
        DatabaseHelper.quotesTable,
        _quoteToMap(quote),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      await _notifyListeners();
    } catch (e) {
      if (e is DuplicateEntityException) {
        rethrow;
      }
      throw DatabaseOperationException('Failed to add quote', e);
    }
  }

  @override
  Future<void> update(Quote entity) async {
    await updateQuote(entity);
  }

  @override
  Future<void> updateQuote(Quote quote) async {
    try {
      final db = await _databaseHelper.database;
      
      final rowsAffected = await db.update(
        DatabaseHelper.quotesTable,
        _quoteToMap(quote),
        where: 'id = ?',
        whereArgs: [quote.id],
      );

      if (rowsAffected == 0) {
        throw EntityNotFoundException('Quote', quote.id);
      }

      await _notifyListeners();
    } catch (e) {
      if (e is EntityNotFoundException) {
        rethrow;
      }
      throw DatabaseOperationException('Failed to update quote', e);
    }
  }

  @override
  Future<void> delete(String id) async {
    await deleteQuote(id);
  }

  @override
  Future<void> deleteQuote(String id) async {
    try {
      final db = await _databaseHelper.database;
      
      final rowsAffected = await db.delete(
        DatabaseHelper.quotesTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw EntityNotFoundException('Quote', id);
      }

      await _notifyListeners();
    } catch (e) {
      if (e is EntityNotFoundException) {
        rethrow;
      }
      throw DatabaseOperationException('Failed to delete quote', e);
    }
  }

  @override
  Future<bool> exists(String id) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.quotesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return maps.isNotEmpty;
    } catch (e) {
      throw DatabaseOperationException('Failed to check if quote exists', e);
    }
  }

  @override
  Future<int> count() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${DatabaseHelper.quotesTable}');
      return result.first['count'] as int;
    } catch (e) {
      throw DatabaseOperationException('Failed to count quotes', e);
    }
  }

  @override
  Future<void> clear() async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(DatabaseHelper.quotesTable);
      await _notifyListeners();
    } catch (e) {
      throw DatabaseOperationException('Failed to clear quotes', e);
    }
  }

  @override
  Stream<List<Quote>> watchAll() {
    // Initialize with current data
    getAll().then((quotes) {
      if (!_quotesController.isClosed) {
        _quotesController.add(quotes);
      }
    }).catchError((error) {
      if (!_quotesController.isClosed) {
        _quotesController.addError(error);
      }
    });

    return _quotesController.stream;
  }

  @override
  Stream<List<Quote>> watchQuotesByBook(String bookId) {
    if (!_bookQuotesControllers.containsKey(bookId)) {
      _bookQuotesControllers[bookId] = StreamController<List<Quote>>.broadcast();
    }

    final controller = _bookQuotesControllers[bookId]!;

    // Initialize with current data
    getQuotesByBook(bookId).then((quotes) {
      if (!controller.isClosed) {
        controller.add(quotes);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    return controller.stream;
  }

  @override
  Stream<Quote?> watchById(String id) {
    if (!_quoteControllers.containsKey(id)) {
      _quoteControllers[id] = StreamController<Quote?>.broadcast();
    }

    final controller = _quoteControllers[id]!;

    // Initialize with current data
    getById(id).then((quote) {
      if (!controller.isClosed) {
        controller.add(quote);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    return controller.stream;
  }

  /// Convert database map to Quote object
  Quote _mapToQuote(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] as String,
      bookId: map['book_id'] as String,
      text: map['text'] as String,
      pageNumber: map['page_number'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Convert Quote object to database map
  Map<String, dynamic> _quoteToMap(Quote quote) {
    return {
      'id': quote.id,
      'book_id': quote.bookId,
      'text': quote.text,
      'page_number': quote.pageNumber,
      'created_at': quote.createdAt.millisecondsSinceEpoch,
    };
  }

  /// Notify all stream listeners of changes
  Future<void> _notifyListeners() async {
    try {
      // Notify all quotes stream
      final allQuotes = await getAll();
      if (!_quotesController.isClosed) {
        _quotesController.add(allQuotes);
      }

      // Notify book-specific quote streams
      for (final entry in _bookQuotesControllers.entries) {
        final bookId = entry.key;
        final controller = entry.value;
        
        if (!controller.isClosed) {
          final bookQuotes = await getQuotesByBook(bookId);
          controller.add(bookQuotes);
        }
      }

      // Notify individual quote streams
      for (final entry in _quoteControllers.entries) {
        final quoteId = entry.key;
        final controller = entry.value;
        
        if (!controller.isClosed) {
          final quote = await getById(quoteId);
          controller.add(quote);
        }
      }
    } catch (e) {
      // Handle errors in notification
      if (!_quotesController.isClosed) {
        _quotesController.addError(e);
      }
      
      for (final controller in _bookQuotesControllers.values) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
      
      for (final controller in _quoteControllers.values) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }
  }

  /// Dispose of all stream controllers
  void dispose() {
    _quotesController.close();
    
    for (final controller in _bookQuotesControllers.values) {
      controller.close();
    }
    _bookQuotesControllers.clear();
    
    for (final controller in _quoteControllers.values) {
      controller.close();
    }
    _quoteControllers.clear();
  }
}