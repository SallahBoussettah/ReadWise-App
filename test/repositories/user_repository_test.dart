import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../lib/models/user_stats.dart';
import '../../lib/models/reading_session.dart';
import '../../lib/models/book.dart';
import '../../lib/models/book_status.dart';
import '../../lib/repositories/database_helper.dart';
import '../../lib/repositories/sqlite_user_repository.dart';
import '../../lib/repositories/sqlite_book_repository.dart';
import '../../lib/repositories/base_repository.dart';

/// Helper method to create test books
Future<void> _createTestBooks(SqliteBookRepository bookRepository) async {
  // Disable foreign key constraints for testing
  final db = await DatabaseHelper.instance.database;
  await db.execute('PRAGMA foreign_keys = OFF');
  
  final testBooks = [
    Book(
      id: 'book-1',
      title: 'Test Book 1',
      author: 'Test Author 1',
      totalPages: 300,
      pagesRead: 0,
      status: BookStatus.reading,
      createdAt: DateTime.now(),
    ),
    Book(
      id: 'book-2',
      title: 'Test Book 2',
      author: 'Test Author 2',
      totalPages: 250,
      pagesRead: 0,
      status: BookStatus.reading,
      createdAt: DateTime.now(),
    ),
  ];

  for (final book in testBooks) {
    try {
      await bookRepository.addBook(book);
    } catch (e) {
      // Ignore duplicate key errors for testing
    }
  }

  // Create additional books for edge case tests
  for (int i = 0; i < 5; i++) {
    try {
      await bookRepository.addBook(Book(
        id: 'book-$i',
        title: 'Test Book $i',
        author: 'Test Author $i',
        totalPages: 200,
        pagesRead: 0,
        status: BookStatus.reading,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      // Ignore duplicate key errors for testing
    }
  }
}

void main() {
  late DatabaseHelper databaseHelper;
  late SqliteUserRepository userRepository;
  late SqliteBookRepository bookRepository;
  const uuid = Uuid();

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper.instance;
    await databaseHelper.deleteDatabase();
    userRepository = SqliteUserRepository(databaseHelper);
    bookRepository = SqliteBookRepository(databaseHelper: databaseHelper);
    
    // Disable foreign key constraints for testing
    final db = await databaseHelper.database;
    await db.execute('PRAGMA foreign_keys = OFF');
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  group('UserRepository - Basic Operations', () {
    test('should return empty stats when no data exists', () async {
      final stats = await userRepository.getUserStats();
      
      expect(stats, equals(UserStats.empty()));
      expect(stats.currentStreak, equals(0));
      expect(stats.longestStreak, equals(0));
      expect(stats.totalBooksRead, equals(0));
      expect(stats.totalPagesRead, equals(0));
      expect(stats.lastReadingDate, isNull);
    });

    test('should update user stats successfully', () async {
      final newStats = UserStats(
        currentStreak: 5,
        longestStreak: 10,
        totalBooksRead: 3,
        totalPagesRead: 500,
        lastReadingDate: DateTime.now(),
      );

      await userRepository.updateUserStats(newStats);
      final retrievedStats = await userRepository.getUserStats();

      expect(retrievedStats.currentStreak, equals(5));
      expect(retrievedStats.longestStreak, equals(10));
      expect(retrievedStats.totalBooksRead, equals(3));
      expect(retrievedStats.totalPagesRead, equals(500));
      expect(retrievedStats.lastReadingDate, isNotNull);
    });

    test('should handle database operation exceptions', () async {
      // Delete the database file to cause an exception
      await databaseHelper.deleteDatabase();
      await databaseHelper.close();
      
      // This should work fine as it will recreate the database
      final stats = await userRepository.getUserStats();
      expect(stats, equals(UserStats.empty()));
    });
  });

  group('UserRepository - Reading Sessions', () {
    test('should log reading session successfully', () async {
      final session = ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        timeSpent: const Duration(minutes: 30),
        sessionDate: DateTime.now(),
      );

      await userRepository.logReadingSession(session);
      final sessions = await userRepository.getReadingSessions();

      expect(sessions.length, equals(1));
      expect(sessions.first.id, equals(session.id));
      expect(sessions.first.bookId, equals('book-1'));
      expect(sessions.first.pagesRead, equals(25));
      expect(sessions.first.timeSpent, equals(const Duration(minutes: 30)));
    });

    test('should update stats after logging session', () async {
      final session = ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: DateTime.now(),
      );

      await userRepository.logReadingSession(session);
      final stats = await userRepository.getUserStats();

      expect(stats.totalPagesRead, equals(25));
      expect(stats.lastReadingDate, isNotNull);
    });

    test('should get reading sessions by book', () async {
      final session1 = ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: DateTime.now(),
      );

      final session2 = ReadingSession(
        id: uuid.v4(),
        bookId: 'book-2',
        pagesRead: 30,
        sessionDate: DateTime.now(),
      );

      await userRepository.logReadingSession(session1);
      await userRepository.logReadingSession(session2);

      final book1Sessions = await userRepository.getReadingSessionsByBook('book-1');
      final book2Sessions = await userRepository.getReadingSessionsByBook('book-2');

      expect(book1Sessions.length, equals(1));
      expect(book1Sessions.first.bookId, equals('book-1'));
      expect(book2Sessions.length, equals(1));
      expect(book2Sessions.first.bookId, equals('book-2'));
    });

    test('should get reading sessions by date range', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      final session1 = ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: today,
      );

      final session2 = ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 30,
        sessionDate: yesterday,
      );

      final session3 = ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 20,
        sessionDate: twoDaysAgo,
      );

      await userRepository.logReadingSession(session1);
      await userRepository.logReadingSession(session2);
      await userRepository.logReadingSession(session3);

      final recentSessions = await userRepository.getReadingSessionsByDateRange(
        yesterday,
        today.add(const Duration(days: 1)),
      );

      expect(recentSessions.length, equals(2));
    });

    test('should get today\'s sessions', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final todaySession = ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: today,
      );

      final yesterdaySession = ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 30,
        sessionDate: yesterday,
      );

      await userRepository.logReadingSession(todaySession);
      await userRepository.logReadingSession(yesterdaySession);

      final todaySessions = await userRepository.getTodaysSessions();

      expect(todaySessions.length, equals(1));
      expect(todaySessions.first.sessionDate.day, equals(today.day));
    });

    test('should get pages read on specific date', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final session1 = ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: today,
      );

      final session2 = ReadingSession(
        id: uuid.v4(),
        bookId: 'book-2',
        pagesRead: 30,
        sessionDate: today,
      );

      final session3 = ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 20,
        sessionDate: yesterday,
      );

      await userRepository.logReadingSession(session1);
      await userRepository.logReadingSession(session2);
      await userRepository.logReadingSession(session3);

      final todayPages = await userRepository.getPagesReadOnDate(today);
      final yesterdayPages = await userRepository.getPagesReadOnDate(yesterday);

      expect(todayPages, equals(55)); // 25 + 30
      expect(yesterdayPages, equals(20));
    });
  });

  group('UserRepository - Streak Calculations', () {
    test('should return 0 streak when no sessions exist', () async {
      final streak = await userRepository.calculateCurrentStreak();
      expect(streak, equals(0));
    });

    test('should calculate streak correctly for consecutive days', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      // Log sessions for consecutive days
      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: today,
      ));

      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 30,
        sessionDate: yesterday,
      ));

      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 20,
        sessionDate: twoDaysAgo,
      ));

      final streak = await userRepository.calculateCurrentStreak();
      expect(streak, equals(3));
    });

    test('should handle gap in reading days', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final threeDaysAgo = today.subtract(const Duration(days: 3));

      // Log sessions with a gap
      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: today,
      ));

      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 30,
        sessionDate: yesterday,
      ));

      // Skip day 2, add session for day 3
      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 20,
        sessionDate: threeDaysAgo,
      ));

      final streak = await userRepository.calculateCurrentStreak();
      expect(streak, equals(2)); // Only today and yesterday count
    });

    test('should return 1 for streak starting yesterday', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: yesterday,
      ));

      final streak = await userRepository.calculateCurrentStreak();
      expect(streak, equals(1));
    });

    test('should return 0 if last reading was more than 1 day ago', () async {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));

      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: threeDaysAgo,
      ));

      final streak = await userRepository.calculateCurrentStreak();
      expect(streak, equals(0));
    });

    test('should check if user has read today', () async {
      expect(await userRepository.hasReadToday(), isFalse);

      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: DateTime.now(),
      ));

      expect(await userRepository.hasReadToday(), isTrue);
    });

    test('should update streak on progress', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // Log sessions for consecutive days
      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: yesterday,
      ));

      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 30,
        sessionDate: today,
      ));

      await userRepository.updateStreakOnProgress();
      final stats = await userRepository.getUserStats();

      expect(stats.currentStreak, equals(2));
      expect(stats.longestStreak, equals(2));
      expect(stats.lastReadingDate, isNotNull);
    });

    test('should update longest streak when current exceeds it', () async {
      // Set initial stats with longest streak of 3
      await userRepository.updateUserStats(UserStats(
        currentStreak: 0,
        longestStreak: 3,
        totalBooksRead: 0,
        totalPagesRead: 0,
      ));

      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      final threeDaysAgo = today.subtract(const Duration(days: 3));
      final fourDaysAgo = today.subtract(const Duration(days: 4));

      // Create a 5-day streak
      for (int i = 0; i < 5; i++) {
        final date = today.subtract(Duration(days: i));
        await userRepository.logReadingSession(ReadingSession(
          id: uuid.v4(),
          bookId: 'book-1',
          pagesRead: 25,
          sessionDate: date,
        ));
      }

      await userRepository.updateStreakOnProgress();
      final stats = await userRepository.getUserStats();

      expect(stats.currentStreak, equals(5));
      expect(stats.longestStreak, equals(5)); // Should be updated
    });

    test('should not reset streak if user read today', () async {
      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: DateTime.now(),
      ));

      await userRepository.updateStreakOnProgress();
      final initialStats = await userRepository.getUserStats();

      await userRepository.resetStreakIfMissed();
      final finalStats = await userRepository.getUserStats();

      expect(finalStats.currentStreak, equals(initialStats.currentStreak));
    });

    test('should not reset streak if user read yesterday', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: yesterday,
      ));

      await userRepository.updateStreakOnProgress();
      final initialStats = await userRepository.getUserStats();

      await userRepository.resetStreakIfMissed();
      final finalStats = await userRepository.getUserStats();

      expect(finalStats.currentStreak, equals(initialStats.currentStreak));
    });

    test('should reset streak if user missed reading for more than a day', () async {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      
      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: threeDaysAgo,
      ));

      await userRepository.updateStreakOnProgress();
      
      // Manually set a streak to test reset
      await userRepository.updateUserStats(UserStats(
        currentStreak: 5,
        longestStreak: 5,
        totalBooksRead: 0,
        totalPagesRead: 25,
        lastReadingDate: threeDaysAgo,
      ));

      await userRepository.resetStreakIfMissed();
      final finalStats = await userRepository.getUserStats();

      expect(finalStats.currentStreak, equals(0));
    });
  });

  group('UserRepository - Edge Cases', () {
    test('should handle multiple sessions on same day for streak calculation', () async {
      final today = DateTime.now();

      // Log multiple sessions today
      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        sessionDate: today,
      ));

      await userRepository.logReadingSession(ReadingSession(
        id: uuid.v4(),
        bookId: 'book-2',
        pagesRead: 30,
        sessionDate: today.add(const Duration(hours: 2)),
      ));

      final streak = await userRepository.calculateCurrentStreak();
      expect(streak, equals(1)); // Should count as one day
    });

    test('should handle sessions with null time spent', () async {
      final session = ReadingSession(
        id: uuid.v4(),
        bookId: 'book-1',
        pagesRead: 25,
        timeSpent: null,
        sessionDate: DateTime.now(),
      );

      await userRepository.logReadingSession(session);
      final sessions = await userRepository.getReadingSessions();

      expect(sessions.length, equals(1));
      expect(sessions.first.timeSpent, isNull);
    });

    test('should handle empty date ranges', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final sessions = await userRepository.getReadingSessionsByDateRange(
        today,
        yesterday, // End before start
      );

      expect(sessions, isEmpty);
    });

    test('should maintain data consistency after multiple operations', () async {
      final today = DateTime.now();
      
      // Log multiple sessions
      for (int i = 0; i < 5; i++) {
        await userRepository.logReadingSession(ReadingSession(
          id: uuid.v4(),
          bookId: 'book-$i',
          pagesRead: 20 + i,
          sessionDate: today.subtract(Duration(hours: i)),
        ));
      }

      final sessions = await userRepository.getReadingSessions();
      final stats = await userRepository.getUserStats();
      final todayPages = await userRepository.getPagesReadOnDate(today);

      expect(sessions.length, equals(5));
      expect(stats.totalPagesRead, equals(110)); // 20+21+22+23+24
      expect(todayPages, equals(110));
      expect(stats.currentStreak, equals(1));
    });
  });
}