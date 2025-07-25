import 'package:flutter_test/flutter_test.dart';
import 'package:reading_companion_app/models/quote.dart';

void main() {
  group('Quote', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    
    final testQuote = Quote(
      id: 'quote-1',
      bookId: 'book-1',
      text: 'This is a test quote',
      pageNumber: 42,
      createdAt: testDate,
    );

    final testQuoteWithoutPage = Quote(
      id: 'quote-2',
      bookId: 'book-1',
      text: 'Quote without page number',
      createdAt: testDate,
    );

    test('should create Quote with all properties', () {
      expect(testQuote.id, 'quote-1');
      expect(testQuote.bookId, 'book-1');
      expect(testQuote.text, 'This is a test quote');
      expect(testQuote.pageNumber, 42);
      expect(testQuote.createdAt, testDate);
    });

    test('should create Quote without page number', () {
      expect(testQuoteWithoutPage.pageNumber, null);
    });

    test('should serialize to JSON correctly', () {
      final json = testQuote.toJson();
      
      expect(json['id'], 'quote-1');
      expect(json['bookId'], 'book-1');
      expect(json['text'], 'This is a test quote');
      expect(json['pageNumber'], 42);
      expect(json['createdAt'], testDate.millisecondsSinceEpoch);
    });

    test('should serialize to JSON correctly without page number', () {
      final json = testQuoteWithoutPage.toJson();
      
      expect(json['pageNumber'], null);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'quote-1',
        'bookId': 'book-1',
        'text': 'This is a test quote',
        'pageNumber': 42,
        'createdAt': testDate.millisecondsSinceEpoch,
      };

      final quote = Quote.fromJson(json);

      expect(quote.id, 'quote-1');
      expect(quote.bookId, 'book-1');
      expect(quote.text, 'This is a test quote');
      expect(quote.pageNumber, 42);
      expect(quote.createdAt, testDate);
    });

    test('should deserialize from JSON correctly without page number', () {
      final json = {
        'id': 'quote-2',
        'bookId': 'book-1',
        'text': 'Quote without page number',
        'pageNumber': null,
        'createdAt': testDate.millisecondsSinceEpoch,
      };

      final quote = Quote.fromJson(json);

      expect(quote.pageNumber, null);
    });

    test('should create copy with modified properties', () {
      final copy = testQuote.copyWith(
        text: 'Modified quote text',
        pageNumber: 100,
      );

      expect(copy.id, testQuote.id);
      expect(copy.bookId, testQuote.bookId);
      expect(copy.text, 'Modified quote text');
      expect(copy.pageNumber, 100);
      expect(copy.createdAt, testQuote.createdAt);
    });

    test('should maintain equality for identical quotes', () {
      final quote1 = Quote(
        id: 'quote-1',
        bookId: 'book-1',
        text: 'Same quote',
        pageNumber: 42,
        createdAt: testDate,
      );

      final quote2 = Quote(
        id: 'quote-1',
        bookId: 'book-1',
        text: 'Same quote',
        pageNumber: 42,
        createdAt: testDate,
      );

      expect(quote1 == quote2, true);
      expect(quote1.hashCode == quote2.hashCode, true);
    });

    test('should not be equal for different quotes', () {
      final quote1 = testQuote;
      final quote2 = testQuoteWithoutPage;

      expect(quote1 == quote2, false);
    });

    test('should have proper toString representation', () {
      final string = testQuote.toString();
      
      expect(string, contains('Quote('));
      expect(string, contains('id: quote-1'));
      expect(string, contains('bookId: book-1'));
      expect(string, contains('text: This is a test quote'));
      expect(string, contains('pageNumber: 42'));
    });

    test('should handle JSON serialization round trip', () {
      final json = testQuote.toJson();
      final deserializedQuote = Quote.fromJson(json);
      
      expect(deserializedQuote, testQuote);
    });
  });
}