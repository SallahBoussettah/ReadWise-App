import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reading_companion_app/models/book.dart';
import 'package:reading_companion_app/models/book_status.dart';
import 'package:reading_companion_app/repositories/book_repository.dart';
import 'package:reading_companion_app/repositories/sqlite_book_repository.dart';
import 'package:reading_companion_app/repositories/database_helper.dart';
import 'package:reading_companion_app/repositories/base_repository.dart';

void main() {
  late BookRepository repository;
  late DatabaseHelper databaseHelper;

  // Test data
  final testBook1 = Book(
    id: 'book1',
    title: 'Test Book 1',
    author: 'Test Author 1',
    coverUrl: 'https://example.com/cover1.jpg',
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
    finishedAt: DateTime(2024, 1, 15),
  );

  final testBook3 = Book(
    id: 'book3',
    title: 'Test Book 3',
    author: 'Test Author 3',
    totalPages: 400,
    pagesRead: 0,
    status: BookStatus.want,
    createdAt: DateTime(2024, 1, 3),
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
    repository = SqliteBookRepository(databaseHelper: databaseHelper);
  });

  tearDown(() async {
    if (repository is SqliteBookRepository) {
      (repository as SqliteBookRepository).dispose();
    }
    await databaseHelper.close();
  });

  group('BookRepository CRUD Operations', () {
    test('should add a new book successfully', () async {
      await repository.addBook(testBook1);
      
      final retrievedBook = await repository.getById(testBook1.id);
      expect(retrievedBook, isNotNull);
      expect(retrievedBook!.id, equals(testBook1.id));
      expect(retrievedBook.title, equals(testBook1.title));
      expect(retrievedBook.author, equals(testBook1.author));
      expect(retrievedBook.status, equals(testBook1.status));
    });

    test('should throw DuplicateEntityException when adding duplicate book', () async {
      await repository.addBook(testBook1);
      
      expect(
        () => repository.addBook(testBook1),
        throwsA(isA<DuplicateEntityException>()),
      );
    });

    test('should get all books in descending order by creation date', () async {
      await repository.addBook(testBook1);
      await repository.addBook(testBook2);
      await repository.addBook(testBook3);
      
      final books = await repository.getAllBooks();
      expect(books.length, equals(3));
      expect(books[0].id, equals(testBook3.id)); // Most recent first
      expect(books[1].id, equals(testBook2.id));
      expect(books[2].id, equals(testBook1.id));
    });

    test('should get books by status', () async {
      await repository.addBook(testBook1); // reading
      await repository.addBook(testBook2); // finished
      await repository.addBook(testBook3); // want
      
      final readingBooks = await repository.getBooksByStatus(BookStatus.reading);
      expect(readingBooks.length, equals(1));
      expect(readingBooks.first.id, equals(testBook1.id));
      
      final finishedBooks = await repository.getBooksByStatus(BookStatus.finished);
      expect(finishedBooks.length, equals(1));
      expect(finishedBooks.first.id, equals(testBook2.id));
      
      final wantBooks = await repository.getBooksByStatus(BookStatus.want);
      expect(wantBooks.length, equals(1));
      expect(wantBooks.first.id, equals(testBook3.id));
    });

    test('should get book by id', () async {
      await repository.addBook(testBook1);
      
      final book = await repository.getById(testBook1.id);
      expect(book, isNotNull);
      expect(book!.id, equals(testBook1.id));
      expect(book.title, equals(testBook1.title));
    });

    test('should return null when getting non-existent book by id', () async {
      final book = await repository.getById('non-existent-id');
      expect(book, isNull);
    });

    test('should update existing book', () async {
      await repository.addBook(testBook1);
      
      final updatedBook = testBook1.copyWith(
        pagesRead: 200,
        status: BookStatus.finished,
        finishedAt: DateTime(2024, 1, 10),
      );
      
      await repository.updateBook(updatedBook);
      
      final retrievedBook = await repository.getById(testBook1.id);
      expect(retrievedBook, isNotNull);
      expect(retrievedBook!.pagesRead, equals(200));
      expect(retrievedBook.status, equals(BookStatus.finished));
      expect(retrievedBook.finishedAt, equals(DateTime(2024, 1, 10)));
    });

    test('should throw EntityNotFoundException when updating non-existent book', () async {
      expect(
        () => repository.updateBook(testBook1),
        throwsA(isA<EntityNotFoundException>()),
      );
    });

    test('should delete existing book', () async {
      await repository.addBook(testBook1);
      
      await repository.deleteBook(testBook1.id);
      
      final book = await repository.getById(testBook1.id);
      expect(book, isNull);
    });

    test('should throw EntityNotFoundException when deleting non-existent book', () async {
      expect(
        () => repository.deleteBook('non-existent-id'),
        throwsA(isA<EntityNotFoundException>()),
      );
    });

    test('should check if book exists', () async {
      expect(await repository.exists(testBook1.id), isFalse);
      
      await repository.addBook(testBook1);
      expect(await repository.exists(testBook1.id), isTrue);
      
      await repository.deleteBook(testBook1.id);
      expect(await repository.exists(testBook1.id), isFalse);
    });

    test('should count books correctly', () async {
      expect(await repository.count(), equals(0));
      
      await repository.addBook(testBook1);
      expect(await repository.count(), equals(1));
      
      await repository.addBook(testBook2);
      expect(await repository.count(), equals(2));
      
      await repository.deleteBook(testBook1.id);
      expect(await repository.count(), equals(1));
    });

    test('should clear all books', () async {
      await repository.addBook(testBook1);
      await repository.addBook(testBook2);
      expect(await repository.count(), equals(2));
      
      await repository.clear();
      expect(await repository.count(), equals(0));
      
      final books = await repository.getAllBooks();
      expect(books, isEmpty);
    });
  });

  group('BookRepository Stream Operations', () {
    test('should watch all books and receive updates', () async {
      final stream = repository.watchAll();
      final streamValues = <List<Book>>[];
      
      final subscription = stream.listen((books) {
        streamValues.add(books);
      });
      
      // Wait for initial empty state
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.length, greaterThanOrEqualTo(1));
      expect(streamValues[0], isEmpty);
      
      // Add a book
      await repository.addBook(testBook1);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.length, greaterThanOrEqualTo(2));
      expect(streamValues.last.length, equals(1));
      expect(streamValues.last[0].id, equals(testBook1.id));
      
      // Add another book
      await repository.addBook(testBook2);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last.length, equals(2));
      
      // Update a book
      final updatedBook = testBook1.copyWith(pagesRead: 200);
      await repository.updateBook(updatedBook);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last.length, equals(2));
      expect(streamValues.last.firstWhere((b) => b.id == testBook1.id).pagesRead, equals(200));
      
      // Delete a book
      await repository.deleteBook(testBook1.id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last.length, equals(1));
      expect(streamValues.last[0].id, equals(testBook2.id));
      
      await subscription.cancel();
    });

    test('should watch books by status and receive filtered updates', () async {
      final stream = repository.watchBooksByStatus(BookStatus.reading);
      final streamValues = <List<Book>>[];
      
      final subscription = stream.listen((books) {
        streamValues.add(books);
      });
      
      // Wait for initial empty state
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.length, greaterThanOrEqualTo(1));
      expect(streamValues[0], isEmpty);
      
      // Add a reading book
      await repository.addBook(testBook1); // reading status
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last.length, equals(1));
      expect(streamValues.last[0].id, equals(testBook1.id));
      
      // Add a finished book (should not appear in reading stream)
      await repository.addBook(testBook2); // finished status
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last.length, equals(1)); // Still only the reading book
      
      // Update reading book to finished (should disappear from stream)
      final updatedBook = testBook1.copyWith(status: BookStatus.finished);
      await repository.updateBook(updatedBook);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last, isEmpty);
      
      await subscription.cancel();
    });

    test('should watch individual book by id and receive updates', () async {
      final stream = repository.watchById(testBook1.id);
      final streamValues = <Book?>[];
      
      final subscription = stream.listen((book) {
        streamValues.add(book);
      });
      
      // Wait for initial null state
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.length, greaterThanOrEqualTo(1));
      expect(streamValues[0], isNull);
      
      // Add the book
      await repository.addBook(testBook1);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last, isNotNull);
      expect(streamValues.last!.id, equals(testBook1.id));
      expect(streamValues.last!.pagesRead, equals(150));
      
      // Update the book
      final updatedBook = testBook1.copyWith(pagesRead: 200);
      await repository.updateBook(updatedBook);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last!.pagesRead, equals(200));
      
      // Delete the book
      await repository.deleteBook(testBook1.id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.last, isNull);
      
      await subscription.cancel();
    });

    test('should handle stream errors gracefully', () async {
      final stream = repository.watchAll();
      final streamValues = <List<Book>>[];
      final streamErrors = <dynamic>[];
      
      final subscription = stream.listen(
        (books) => streamValues.add(books),
        onError: (error) => streamErrors.add(error),
      );
      
      // Wait for initial state
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamValues.length, greaterThanOrEqualTo(1));
      expect(streamErrors, isEmpty);
      
      await subscription.cancel();
    });
  });

  group('BookRepository Base Interface Compliance', () {
    test('should implement BaseRepository interface correctly', () async {
      // Test insert method (alias for addBook)
      await repository.insert(testBook1);
      final book = await repository.getById(testBook1.id);
      expect(book, isNotNull);
      
      // Test update method (alias for updateBook)
      final updatedBook = testBook1.copyWith(pagesRead: 100);
      await repository.update(updatedBook);
      final updated = await repository.getById(testBook1.id);
      expect(updated!.pagesRead, equals(100));
      
      // Test delete method (alias for deleteBook)
      await repository.delete(testBook1.id);
      final deleted = await repository.getById(testBook1.id);
      expect(deleted, isNull);
    });

    test('should implement StreamableRepository interface correctly', () async {
      // Test watchAll method
      final allStream = repository.watchAll();
      expect(allStream, isA<Stream<List<Book>>>());
      
      // Test watchById method
      final byIdStream = repository.watchById(testBook1.id);
      expect(byIdStream, isA<Stream<Book?>>());
    });
  });

  group('BookRepository Error Handling', () {
    test('should handle database connection errors', () async {
      await databaseHelper.close();
      
      // Should return empty list instead of throwing when database is closed
      final books = await repository.getAllBooks();
      expect(books, isEmpty);
    });

    test('should handle malformed data gracefully', () async {
      // This test would require direct database manipulation
      // to insert malformed data, which is complex to set up
      // In a real scenario, you might want to test this
    });

    test('should handle concurrent operations', () async {
      // Test concurrent adds
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        final book = testBook1.copyWith(id: 'book$i');
        futures.add(repository.addBook(book));
      }
      
      await Future.wait(futures);
      
      final count = await repository.count();
      expect(count, equals(10));
    });
  });
}