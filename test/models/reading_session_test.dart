import 'package:flutter_test/flutter_test.dart';
import 'package:reading_companion_app/models/reading_session.dart';

void main() {
  group('ReadingSession', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final testDuration = Duration(minutes: 45);
    
    final testSession = ReadingSession(
      id: 'session-1',
      bookId: 'book-1',
      pagesRead: 25,
      timeSpent: testDuration,
      sessionDate: testDate,
    );

    final testSessionWithoutTime = ReadingSession(
      id: 'session-2',
      bookId: 'book-1',
      pagesRead: 10,
      sessionDate: testDate,
    );

    test('should create ReadingSession with all properties', () {
      expect(testSession.id, 'session-1');
      expect(testSession.bookId, 'book-1');
      expect(testSession.pagesRead, 25);
      expect(testSession.timeSpent, testDuration);
      expect(testSession.sessionDate, testDate);
    });

    test('should create ReadingSession without time spent', () {
      expect(testSessionWithoutTime.timeSpent, null);
    });

    test('should serialize to JSON correctly', () {
      final json = testSession.toJson();
      
      expect(json['id'], 'session-1');
      expect(json['bookId'], 'book-1');
      expect(json['pagesRead'], 25);
      expect(json['timeSpent'], 45); // Duration in minutes
      expect(json['sessionDate'], testDate.millisecondsSinceEpoch);
    });

    test('should serialize to JSON correctly without time spent', () {
      final json = testSessionWithoutTime.toJson();
      
      expect(json['timeSpent'], null);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'session-1',
        'bookId': 'book-1',
        'pagesRead': 25,
        'timeSpent': 45,
        'sessionDate': testDate.millisecondsSinceEpoch,
      };

      final session = ReadingSession.fromJson(json);

      expect(session.id, 'session-1');
      expect(session.bookId, 'book-1');
      expect(session.pagesRead, 25);
      expect(session.timeSpent, Duration(minutes: 45));
      expect(session.sessionDate, testDate);
    });

    test('should deserialize from JSON correctly without time spent', () {
      final json = {
        'id': 'session-2',
        'bookId': 'book-1',
        'pagesRead': 10,
        'timeSpent': null,
        'sessionDate': testDate.millisecondsSinceEpoch,
      };

      final session = ReadingSession.fromJson(json);

      expect(session.timeSpent, null);
    });

    test('should create copy with modified properties', () {
      final copy = testSession.copyWith(
        pagesRead: 50,
        timeSpent: Duration(minutes: 60),
      );

      expect(copy.id, testSession.id);
      expect(copy.bookId, testSession.bookId);
      expect(copy.pagesRead, 50);
      expect(copy.timeSpent, Duration(minutes: 60));
      expect(copy.sessionDate, testSession.sessionDate);
    });

    test('should maintain equality for identical sessions', () {
      final session1 = ReadingSession(
        id: 'session-1',
        bookId: 'book-1',
        pagesRead: 25,
        timeSpent: testDuration,
        sessionDate: testDate,
      );

      final session2 = ReadingSession(
        id: 'session-1',
        bookId: 'book-1',
        pagesRead: 25,
        timeSpent: testDuration,
        sessionDate: testDate,
      );

      expect(session1 == session2, true);
      expect(session1.hashCode == session2.hashCode, true);
    });

    test('should not be equal for different sessions', () {
      final session1 = testSession;
      final session2 = testSessionWithoutTime;

      expect(session1 == session2, false);
    });

    test('should have proper toString representation', () {
      final string = testSession.toString();
      
      expect(string, contains('ReadingSession('));
      expect(string, contains('id: session-1'));
      expect(string, contains('bookId: book-1'));
      expect(string, contains('pagesRead: 25'));
      expect(string, contains('timeSpent: 0:45:00.000000'));
    });

    test('should handle JSON serialization round trip', () {
      final json = testSession.toJson();
      final deserializedSession = ReadingSession.fromJson(json);
      
      expect(deserializedSession, testSession);
    });

    test('should handle JSON serialization round trip without time', () {
      final json = testSessionWithoutTime.toJson();
      final deserializedSession = ReadingSession.fromJson(json);
      
      expect(deserializedSession, testSessionWithoutTime);
    });
  });
}