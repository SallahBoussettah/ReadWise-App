import 'package:flutter_test/flutter_test.dart';
import 'package:reading_companion_app/models/models.dart';

void main() {
  group('Models Export', () {
    test('should export all model classes', () {
      // Test that all models can be imported from the barrel file
      expect(Book, isNotNull);
      expect(BookStatus, isNotNull);
      expect(Quote, isNotNull);
      expect(ReadingSession, isNotNull);
      expect(UserStats, isNotNull);
    });

    test('should be able to create instances of all models', () {
      final testDate = DateTime.now();
      
      // Test BookStatus enum
      expect(BookStatus.want, isA<BookStatus>());
      
      // Test Quote model
      final quote = Quote(
        id: 'test',
        bookId: 'book-test',
        text: 'Test quote',
        createdAt: testDate,
      );
      expect(quote, isA<Quote>());
      
      // Test ReadingSession model
      final session = ReadingSession(
        id: 'session-test',
        bookId: 'book-test',
        pagesRead: 10,
        sessionDate: testDate,
      );
      expect(session, isA<ReadingSession>());
      
      // Test UserStats model
      final stats = UserStats.empty();
      expect(stats, isA<UserStats>());
      
      // Test Book model
      final book = Book(
        id: 'book-test',
        title: 'Test Book',
        author: 'Test Author',
        totalPages: 100,
        status: BookStatus.want,
        createdAt: testDate,
      );
      expect(book, isA<Book>());
    });
  });
}