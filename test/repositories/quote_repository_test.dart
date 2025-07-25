import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reading_companion_app/models/quote.dart';
import 'package:reading_companion_app/models/book.dart';
import 'package:reading_companion_app/models/book_status.dart';
import 'package:reading_companion_app/repositories/quote_repository.dart';
import 'package:reading_companion_app/repositories/sqlite_quote_repository.dart';
import 'package:reading_companion_app/repositories/book_repository.dart';
import 'package:reading_companion_app/repositories/sqlite_book_repository.dart';
import 'package:reading_companion_app/repositories/database_helper.dart';
import 'package:reading_companion_app/repositories/base_repository.dart';

void main() {
  late QuoteRepository repository;
  late BookRepository bookRepository;
  late DatabaseHelper databaseHelper;

  // Test data
  final testBook1 = Book(
    id: 'book1',
    title: 'Test Book 1',
    author: 'Test Author 1',
    totalPages: 300,
    pagesRead: 150,
    status: BookStatus.reading,
    createdAt: DateTime(2024, 1, 1),
  );

  final testBook2 = Book(
    id: 'book2',
    title: 'Test Book 2',
    author: 'Test Author 2',
    totalPages: 250,
    pagesRead: 250,
    status: BookStatus.finished,
    createdAt: DateTime(2024, 1, 2),
  );

  final testQuote1 = Quote(
    id: 'quote1',
    bookId: 'book1',
    text: 'This is a test quote from book 1',
    pageNumber: 42,
    createdAt: DateTime(2024, 1, 1, 10, 0),
  );

  final testQuote2 = Quote(
    id: 'quote2',
    bookId: 'book1',
    text: 'Another quote from book 1',
    pageNumber: 85,
    createdAt: DateTime(2024, 1, 1, 15, 0),
  );

  final testQuote3 = Quote(
    id: 'quote3',
    bookId: 'book2',
    text: 'A quote from book 2',
    createdAt: DateTime(2024, 1, 2, 12, 0),
  );

  final testQuote4 = Quote(
    id: 'quote4',
    bookId: 'book1',
    text: 'Latest quote from book 1',
    pageNumber: 120,
    createdAt: DateTime(2024, 1, 3, 9, 0),
  );

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create a fresh in-memory database for each test
    databaseHelper = DatabaseHelper.instance;
    await databaseHelper.deleteDatabase();
    repository = SqliteQuoteRepository(databaseHelper: databaseHelper);
    bookRepository = SqliteBookRepository(databaseHelper: databaseHelper);
    
    // Add test books for foreign key relationships
    await bookRepository.addBook(testBook1);
    await bookRepository.addBook(testBook2);
  });

  tearDown(() async {
    if (repository is SqliteQuoteRepository) {
      (repository as SqliteQuoteRepository).dispose();
    }
    if (bookRepository is SqliteBookRepository) {
      (bookRepository as SqliteBookRepository).dispose();
    }
    await databaseHelper.close();
  });

  group('QuoteRepository CRUD Operations', () {
    test('should add a new quote successfully', () async {
      await repository.addQuote(testQuote1);
      
      final retrievedQuote = await repository.getById(testQuote1.id);
      expect(retrievedQuote, isNotNull);
      expect(retrievedQuote!.id, equals(testQuote1.id));
      expect(retrievedQuote.bookId, equals(testQuote1.bookId));
      expect(retrievedQuote.text, equals(testQuote1.text));
      expect(retrievedQuote.pageNumber, equals(testQuote1.pageNumber));
      expect(retrievedQuote.createdAt, equals(testQuote1.createdAt));
    });

    test('should throw DuplicateEntityException when adding duplicate quote', () async {
      await repository.addQuote(testQuote1);
      
      expect(
        () => repository.addQuote(testQuote1),
        throwsA(isA<DuplicateEntityException>()),
      );
    });

    test('should get all quotes in descending order by creation date', () async {
      await repository.addQuote(testQuote1); // 2024-01-01 10:00
      await repository.addQuote(testQuote2); // 2024-01-01 15:00
      await repository.addQuote(testQuote3); // 2024-01-02 12:00
      await repository.addQuote(testQuote4); // 2024-01-03 09:00
      
      final quotes = await repository.getAllQuotes();
      expect(quotes.length, equals(4));
      expect(quotes[0].id, equals(testQuote4.id)); // Most recent first
      expect(quotes[1].id, equals(testQuote3.id));
      expect(quotes[2].id, equals(testQuote2.id));
      expect(quotes[3].id, equals(testQuote1.id));
    });

    test('should get quotes by book ID', () async {
      await repository.addQuote(testQuote1); // book1
      await repository.addQuote(testQuote2); // book1
      await repository.addQuote(testQuote3); // book2
      await repository.addQuote(testQuote4); // book1
      
      final book1Quotes = await repository.getQuotesByBook('book1');
      expect(book1Quotes.length, equals(3));
      expect(book1Quotes[0].id, equals(testQuote4.id)); // Most recent first
      expect(book1Quotes[1].id, equals(testQuote2.id));
      expect(book1Quotes[2].id, equals(testQuote1.id));
      
      final book2Quotes = await repository.getQuotesByBook('book2');
      expect(book2Quotes.length, equals(1));
      expect(book2Quotes[0].id, equals(testQuote3.id));
      
      final nonExistentBookQuotes = await repository.getQuotesByBook('nonexistent');
      expect(nonExistentBookQuotes, isEmpty);
    });

    test('should get quote by id', () async {
      await repository.addQuote(testQuote1);
      
      final quote = await repository.getById(testQuote1.id);
      expect(quote, isNotNull);
      expect(quote!.id, equals(testQuote1.id));
      expect(quote.text, equals(testQuote1.text));
      expect(quote.bookId, equals(testQuote1.bookId));
    });

    test('should return null when getting non-existent quote by id', () async {
      final quote = await repository.getById('non-existent-id');
      expect(quote, isNull);
    });

    test('should update existing quote', () async {
      await repository.addQuote(testQuote1);
      
      final updatedQuote = testQuote1.copyWith(
        text: 'Updated quote text',
        pageNumber: 99,
      );
      
      await repository.updateQuote(updatedQuote);
      
      final retrievedQuote = await repository.getById(testQuote1.id);
      expect(retrievedQuote, isNotNull);
      expect(retrievedQuote!.text, equals('Updated quote text'));
      expect(retrievedQuote.pageNumber, equals(99));
      expect(retrievedQuote.bookId, equals(testQuote1.bookId)); // Should remain unchanged
      expect(retrievedQuote.createdAt, equals(testQuote1.createdAt)); // Should remain unchanged
    });

    test('should throw EntityNotFoundException when updating non-existent quote', () async {
      expect(
        () => repository.updateQuote(testQuote1),
        throwsA(isA<EntityNotFoundException>()),
      );
    });

    test('should delete existing quote', () async {
      await repository.addQuote(testQuote1);
      
      await repository.deleteQuote(testQuote1.id);
      
      final quote = await repository.getById(testQuote1.id);
      expect(quote, isNull);
    });

    test('should throw EntityNotFoundException when deleting non-existent quote', () async {
      expect(
        () => repository.deleteQuote('non-existent-id'),
        throwsA(isA<EntityNotFoundException>()),
      );
    });

    test('should check if quote exists', () async {
      expect(await repository.exists(testQuote1.id), isFalse);
      
      await repository.addQuote(testQuote1);
      expect(await repository.exists(testQuote1.id), isTrue);
      
      await repository.deleteQuote(testQuote1.id);
      expect(await repository.exists(testQuote1.id), isFalse);
    });

    test('should count quotes correctly', () async {
      expect(await repository.count(), equals(0));
      
      await repository.addQuote(testQuote1);
      expect(await repository.count(), equals(1));
      
      await repository.addQuote(testQuote2);
      expect(await repository.count(), equals(2));
      
      await repository.deleteQuote(testQuote1.id);
      expect(await repository.count(), equals(1));
    });

    test('should clear all quotes', () async {
      await repository.addQuote(testQuote1);
      await repository.addQuote(testQuote2);
      expect(await repository.count(), equals(2));
      
      await repository.clear();
      expect(await repository.count(), equals(0));
      
      final quotes = await repository.getAllQuotes();
      expect(quotes, isEmpty);
    });
  });

  group('QuoteRepository Random Quote Functionality', () {
    test('should return null when no quotes exist', () async {
      final randomQuote = await repository.getRandomQuote();
      expect(randomQuote, isNull);
    });

    test('should return the only quote when one exists', () async {
      await repository.addQuote(testQuote1);
      
      final randomQuote = await repository.getRandomQuote();
      expect(randomQuote, isNotNull);
      expect(randomQuote!.id, equals(testQuote1.id));
    });

    test('should return a random quote from multiple quotes', () async {
      await repository.addQuote(testQuote1);
      await repository.addQuote(testQuote2);
      await repository.addQuote(testQuote3);
      await repository.addQuote(testQuote4);
      
      final allQuoteIds = {testQuote1.id, testQuote2.id, testQuote3.id, testQuote4.id};
      final returnedIds = <String>{};
      
      // Call getRandomQuote multiple times to test randomness
      for (int i = 0; i < 20; i++) {
        final randomQuote = await repository.getRandomQuote();
        expect(randomQuote, isNotNull);
        expect(allQuoteIds.contains(randomQuote!.id), isTrue);
        returnedIds.add(randomQuote.id);
      }
      
      // With 20 calls and 4 quotes, we should get some variety
      // (This is probabilistic, but very likely to pass)
      expect(returnedIds.length, greaterThan(1));
    });

    test('should return null after all quotes are deleted', () async {
      await repository.addQuote(testQuote1);
      await repository.addQuote(testQuote2);
      
      // Verify quotes exist
      expect(await repository.getRandomQuote(), isNotNull);
      
      // Clear all quotes
      await repository.clear();
      
      // Should return null now
      final randomQuote = await repository.getRandomQuote();
      expect(randomQuote, isNull);
    });
  });

  group('QuoteRepository Stream Operations', () {
    test('should watch all quotes and receive updates', () async {
      final stream = repository.watchAll();
      final streamValues = <List<Quote>>[];
      
      final subscription = stream.listen((quotes) {
        streamValues.add(quotes);
      });
      
      // Wait for initial empty state
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.length, greaterThanOrEqualTo(1));
      expect(streamValues[0], isEmpty);
      
      // Add a quote
      await repository.addQuote(testQuote1);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.length, greaterThanOrEqualTo(2));
      expect(streamValues.last.length, equals(1));
      expect(streamValues.last[0].id, equals(testQuote1.id));
      
      // Add another quote
      await repository.addQuote(testQuote2);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last.length, equals(2));
      
      // Update a quote
      final updatedQuote = testQuote1.copyWith(text: 'Updated text');
      await repository.updateQuote(updatedQuote);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last.length, equals(2));
      expect(streamValues.last.firstWhere((q) => q.id == testQuote1.id).text, equals('Updated text'));
      
      // Delete a quote
      await repository.deleteQuote(testQuote1.id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last.length, equals(1));
      expect(streamValues.last[0].id, equals(testQuote2.id));
      
      await subscription.cancel();
    });

    test('should watch quotes by book and receive filtered updates', () async {
      final stream = repository.watchQuotesByBook('book1');
      final streamValues = <List<Quote>>[];
      
      final subscription = stream.listen((quotes) {
        streamValues.add(quotes);
      });
      
      // Wait for initial empty state
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.length, greaterThanOrEqualTo(1));
      expect(streamValues[0], isEmpty);
      
      // Add a quote for book1
      await repository.addQuote(testQuote1); // book1
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last.length, equals(1));
      expect(streamValues.last[0].id, equals(testQuote1.id));
      
      // Add a quote for book2 (should not appear in book1 stream)
      await repository.addQuote(testQuote3); // book2
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last.length, equals(1)); // Still only the book1 quote
      
      // Add another quote for book1
      await repository.addQuote(testQuote2); // book1
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last.length, equals(2));
      
      // Delete book1 quote
      await repository.deleteQuote(testQuote1.id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last.length, equals(1));
      expect(streamValues.last[0].id, equals(testQuote2.id));
      
      await subscription.cancel();
    });

    test('should watch individual quote by id and receive updates', () async {
      final stream = repository.watchById(testQuote1.id);
      final streamValues = <Quote?>[];
      
      final subscription = stream.listen((quote) {
        streamValues.add(quote);
      });
      
      // Wait for initial null state
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.length, greaterThanOrEqualTo(1));
      expect(streamValues[0], isNull);
      
      // Add the quote
      await repository.addQuote(testQuote1);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last, isNotNull);
      expect(streamValues.last!.id, equals(testQuote1.id));
      expect(streamValues.last!.text, equals(testQuote1.text));
      
      // Update the quote
      final updatedQuote = testQuote1.copyWith(text: 'Updated text');
      await repository.updateQuote(updatedQuote);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last!.text, equals('Updated text'));
      
      // Delete the quote
      await repository.deleteQuote(testQuote1.id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last, isNull);
      
      await subscription.cancel();
    });

    test('should handle stream errors gracefully', () async {
      final stream = repository.watchAll();
      final streamValues = <List<Quote>>[];
      final streamErrors = <dynamic>[];
      
      final subscription = stream.listen(
        (quotes) => streamValues.add(quotes),
        onError: (error) => streamErrors.add(error),
      );
      
      // Wait for initial state
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.length, greaterThanOrEqualTo(1));
      expect(streamErrors, isEmpty);
      
      await subscription.cancel();
    });
  });

  group('QuoteRepository Base Interface Compliance', () {
    test('should implement BaseRepository interface correctly', () async {
      // Test insert method (alias for addQuote)
      await repository.insert(testQuote1);
      final quote = await repository.getById(testQuote1.id);
      expect(quote, isNotNull);
      
      // Test update method (alias for updateQuote)
      final updatedQuote = testQuote1.copyWith(text: 'Updated text');
      await repository.update(updatedQuote);
      final updated = await repository.getById(testQuote1.id);
      expect(updated!.text, equals('Updated text'));
      
      // Test delete method (alias for deleteQuote)
      await repository.delete(testQuote1.id);
      final deleted = await repository.getById(testQuote1.id);
      expect(deleted, isNull);
    });

    test('should implement StreamableRepository interface correctly', () async {
      // Test watchAll method
      final allStream = repository.watchAll();
      expect(allStream, isA<Stream<List<Quote>>>());
      
      // Test watchById method
      final byIdStream = repository.watchById(testQuote1.id);
      expect(byIdStream, isA<Stream<Quote?>>());
    });
  });

  group('QuoteRepository Error Handling', () {
    test('should handle database connection errors', () async {
      await databaseHelper.close();
      
      // Should return empty list instead of throwing when database is closed
      final quotes = await repository.getAllQuotes();
      expect(quotes, isEmpty);
    });

    test('should handle concurrent operations', () async {
      // Test concurrent adds
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        final quote = testQuote1.copyWith(id: 'quote$i');
        futures.add(repository.addQuote(quote));
      }
      
      await Future.wait(futures);
      
      final count = await repository.count();
      expect(count, equals(10));
    });

    test('should handle quotes with null page numbers', () async {
      final quoteWithoutPage = Quote(
        id: 'quote_no_page',
        bookId: 'book1',
        text: 'Quote without page number',
        createdAt: DateTime.now(),
      );
      
      await repository.addQuote(quoteWithoutPage);
      
      final retrieved = await repository.getById('quote_no_page');
      expect(retrieved, isNotNull);
      expect(retrieved!.pageNumber, isNull);
      expect(retrieved.text, equals('Quote without page number'));
    });

    test('should handle empty text gracefully', () async {
      final emptyQuote = testQuote1.copyWith(text: '');
      
      await repository.addQuote(emptyQuote);
      
      final retrieved = await repository.getById(testQuote1.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.text, equals(''));
    });

    test('should handle very long quote text', () async {
      final longText = 'A' * 10000; // Very long text
      final longQuote = testQuote1.copyWith(text: longText);
      
      await repository.addQuote(longQuote);
      
      final retrieved = await repository.getById(testQuote1.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.text, equals(longText));
    });
  });

  group('QuoteRepository Foreign Key Relationships', () {
    test('should maintain referential integrity with books', () async {
      // Add quote for existing book
      await repository.addQuote(testQuote1);
      final quote = await repository.getById(testQuote1.id);
      expect(quote, isNotNull);
      
      // Verify the book exists
      final book = await bookRepository.getById(testQuote1.bookId);
      expect(book, isNotNull);
    });

    test('should maintain quotes when book exists', () async {
      // Add quotes for book1
      await repository.addQuote(testQuote1);
      await repository.addQuote(testQuote2);
      
      // Verify quotes exist and are associated with the book
      expect(await repository.count(), equals(2));
      final book1Quotes = await repository.getQuotesByBook('book1');
      expect(book1Quotes.length, equals(2));
      
      // Verify the book still exists
      final book = await bookRepository.getById('book1');
      expect(book, isNotNull);
    });
  });
}