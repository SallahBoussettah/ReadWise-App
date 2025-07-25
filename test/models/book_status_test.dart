import 'package:flutter_test/flutter_test.dart';
import 'package:reading_companion_app/models/book_status.dart';

void main() {
  group('BookStatus', () {
    test('should have correct values', () {
      expect(BookStatus.want.value, 'want');
      expect(BookStatus.reading.value, 'reading');
      expect(BookStatus.finished.value, 'finished');
    });

    test('should convert from string correctly', () {
      expect(BookStatus.fromString('want'), BookStatus.want);
      expect(BookStatus.fromString('reading'), BookStatus.reading);
      expect(BookStatus.fromString('finished'), BookStatus.finished);
    });

    test('should throw ArgumentError for invalid string', () {
      expect(() => BookStatus.fromString('invalid'), throwsArgumentError);
      expect(() => BookStatus.fromString(''), throwsArgumentError);
    });

    test('toString should return correct value', () {
      expect(BookStatus.want.toString(), 'want');
      expect(BookStatus.reading.toString(), 'reading');
      expect(BookStatus.finished.toString(), 'finished');
    });

    test('should be comparable', () {
      expect(BookStatus.want == BookStatus.want, true);
      expect(BookStatus.want == BookStatus.reading, false);
    });
  });
}