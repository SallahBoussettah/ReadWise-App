import 'package:flutter_test/flutter_test.dart';
import 'package:reading_companion_app/models/book.dart';
import 'package:reading_companion_app/models/book_status.dart';
import 'package:reading_companion_app/models/quote.dart';

void main() {
  group('Book', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final finishedDate = DateTime(2024, 2, 1, 15, 45);
    
    final testQuote = Quote(
      id: 'quote-1',
      bookId: 'book-1',
      text: 'Test quote',
      pageNumber: 42,
      createdAt: testDate,
    );

    final testBook = Book(
      id: 'book-1',
      title: 'Test Book',
      author: 'Test Author',
      coverUrl: 'https://example.com/cover.jpg',
      totalPages: 300,
      pagesRead: 150,
      status: BookStatus.reading,
      createdAt: testDate,
      quotes: [testQuote],
    );

    final finishedBook = Book(
      id: 'book-2',
      title: 'Finished Book',
      author: 'Another Author',
      totalPages: 200,
      pagesRead: 200,
      status: BookStatus.finished,
      createdAt: testDate,
      finishedAt: finishedDate,
    );

    test('should create Book with all properties', () {
      expect(testBook.id, 'book-1');
      expect(testBook.title, 'Test Book');
      expect(testBook.author, 'Test Author');
      expect(testBook.coverUrl, 'https://example.com/cover.jpg');
      expect(testBook.totalPages, 300);
      expect(testBook.pagesRead, 150);
      expect(testBook.status, BookStatus.reading);
      expect(testBook.createdAt, testDate);
      expect(testBook.finishedAt, null);
      expect(testBook.quotes.length, 1);
      expect(testBook.quotes.first, testQuote);
    });

    test('should calculate progress percentage correctly', () {
      expect(testBook.progressPercentage, 0.5); // 150/300 = 0.5
      expect(finishedBook.progressPercentage, 1.0); // 200/200 = 1.0
      
      final zeroPageBook = testBook.copyWith(totalPages: 0);
      expect(zeroPageBook.progressPercentage, 0.0);
      
      final overProgressBook = testBook.copyWith(pagesRead: 400);
      expect(overProgressBook.progressPercentage, 1.0); // Clamped to 1.0
    });

    test('should determine if book is finished correctly', () {
      expect(testBook.isFinished, false);
      expect(finishedBook.isFinished, true);
      
      final completeBook = testBook.copyWith(pagesRead: 300);
      expect(completeBook.isFinished, true); // 100% progress
    });

    test('should serialize to JSON correctly', () {
      final json = testBook.toJson();
      
      expect(json['id'], 'book-1');
      expect(json['title'], 'Test Book');
      expect(json['author'], 'Test Author');
      expect(json['coverUrl'], 'https://example.com/cover.jpg');
      expect(json['totalPages'], 300);
      expect(json['pagesRead'], 150);
      expect(json['status'], 'reading');
      expect(json['createdAt'], testDate.millisecondsSinceEpoch);
      expect(json['finishedAt'], null);
      expect(json['quotes'], isA<List>());
      expect(json['quotes'].length, 1);
    });

    test('should serialize finished book to JSON correctly', () {
      final json = finishedBook.toJson();
      
      expect(json['finishedAt'], finishedDate.millisecondsSinceEpoch);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'book-1',
        'title': 'Test Book',
        'author': 'Test Author',
        'coverUrl': 'https://example.com/cover.jpg',
        'totalPages': 300,
        'pagesRead': 150,
        'status': 'reading',
        'createdAt': testDate.millisecondsSinceEpoch,
        'finishedAt': null,
        'quotes': [testQuote.toJson()],
      };

      final book = Book.fromJson(json);

      expect(book.id, 'book-1');
      expect(book.title, 'Test Book');
      expect(book.author, 'Test Author');
      expect(book.coverUrl, 'https://example.com/cover.jpg');
      expect(book.totalPages, 300);
      expect(book.pagesRead, 150);
      expect(book.status, BookStatus.reading);
      expect(book.createdAt, testDate);
      expect(book.finishedAt, null);
      expect(book.quotes.length, 1);
      expect(book.quotes.first.id, testQuote.id);
    });

    test('should deserialize from JSON with default values', () {
      final json = {
        'id': 'book-2',
        'title': 'Minimal Book',
        'author': 'Author',
        'totalPages': 100,
        'status': 'want',
        'createdAt': testDate.millisecondsSinceEpoch,
      };

      final book = Book.fromJson(json);

      expect(book.pagesRead, 0); // Default value
      expect(book.coverUrl, null);
      expect(book.finishedAt, null);
      expect(book.quotes, isEmpty);
    });

    test('should create copy with modified properties', () {
      final copy = testBook.copyWith(
        title: 'Modified Title',
        pagesRead: 200,
        status: BookStatus.finished,
        finishedAt: finishedDate,
      );

      expect(copy.id, testBook.id);
      expect(copy.title, 'Modified Title');
      expect(copy.author, testBook.author);
      expect(copy.pagesRead, 200);
      expect(copy.status, BookStatus.finished);
      expect(copy.finishedAt, finishedDate);
      expect(copy.quotes, testBook.quotes);
    });

    test('should maintain equality for identical books', () {
      final book1 = Book(
        id: 'book-1',
        title: 'Same Book',
        author: 'Same Author',
        totalPages: 300,
        pagesRead: 150,
        status: BookStatus.reading,
        createdAt: testDate,
        quotes: [testQuote],
      );

      final book2 = Book(
        id: 'book-1',
        title: 'Same Book',
        author: 'Same Author',
        totalPages: 300,
        pagesRead: 150,
        status: BookStatus.reading,
        createdAt: testDate,
        quotes: [testQuote],
      );

      expect(book1 == book2, true);
      expect(book1.hashCode == book2.hashCode, true);
    });

    test('should not be equal for different books', () {
      final book1 = testBook;
      final book2 = finishedBook;

      expect(book1 == book2, false);
    });

    test('should not be equal for books with different quotes', () {
      final book1 = testBook;
      final book2 = testBook.copyWith(quotes: []);

      expect(book1 == book2, false);
    });

    test('should have proper toString representation', () {
      final string = testBook.toString();
      
      expect(string, contains('Book('));
      expect(string, contains('id: book-1'));
      expect(string, contains('title: Test Book'));
      expect(string, contains('author: Test Author'));
      expect(string, contains('totalPages: 300'));
      expect(string, contains('pagesRead: 150'));
      expect(string, contains('status: reading'));
      expect(string, contains('1 quotes'));
    });

    test('should handle JSON serialization round trip', () {
      final json = testBook.toJson();
      final deserializedBook = Book.fromJson(json);
      
      expect(deserializedBook, testBook);
    });

    test('should handle JSON serialization round trip for finished book', () {
      final json = finishedBook.toJson();
      final deserializedBook = Book.fromJson(json);
      
      expect(deserializedBook, finishedBook);
    });

    test('should handle empty quotes list', () {
      final bookWithoutQuotes = testBook.copyWith(quotes: []);
      final json = bookWithoutQuotes.toJson();
      final deserializedBook = Book.fromJson(json);
      
      expect(deserializedBook.quotes, isEmpty);
      expect(deserializedBook, bookWithoutQuotes);
    });
  });
}