import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/user_stats.dart';
import '../models/reading_session.dart';
import 'user_repository.dart';
import 'database_helper.dart';
import 'base_repository.dart';

/// SQLite implementation of UserRepository
class SqliteUserRepository implements UserRepository {
  final DatabaseHelper _databaseHelper;
  final Uuid _uuid = const Uuid();

  SqliteUserRepository(this._databaseHelper);

  @override
  Future<UserStats> getUserStats() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.userStatsTable,
        where: 'id = ?',
        whereArgs: [1], // Single user stats record
      );

      if (maps.isEmpty) {
        // Return empty stats if no record exists
        return UserStats.empty();
      }

      return UserStats.fromJson(maps.first);
    } catch (e) {
      throw DatabaseOperationException('Failed to get user stats', e);
    }
  }

  @override
  Future<void> updateUserStats(UserStats stats) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        DatabaseHelper.userStatsTable,
        stats.toJson(),
        where: 'id = ?',
        whereArgs: [1],
      );
    } catch (e) {
      throw DatabaseOperationException('Failed to update user stats', e);
    }
  }

  @override
  Future<void> logReadingSession(ReadingSession session) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        DatabaseHelper.readingSessionsTable,
        {
          'id': session.id,
          'book_id': session.bookId,
          'pages_read': session.pagesRead,
          'time_spent': session.timeSpent?.inMinutes,
          'session_date': session.sessionDate.millisecondsSinceEpoch,
        },
      );

      // Update user stats after logging session
      await _updateStatsAfterSession(session);
    } catch (e) {
      throw DatabaseOperationException('Failed to log reading session', e);
    }
  }

  @override
  Future<List<ReadingSession>> getReadingSessions() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.readingSessionsTable,
        orderBy: 'session_date DESC',
      );

      return maps.map((map) => _mapToReadingSession(map)).toList();
    } catch (e) {
      throw DatabaseOperationException('Failed to get reading sessions', e);
    }
  }

  @override
  Future<List<ReadingSession>> getReadingSessionsByBook(String bookId) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.readingSessionsTable,
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'session_date DESC',
      );

      return maps.map((map) => _mapToReadingSession(map)).toList();
    } catch (e) {
      throw DatabaseOperationException('Failed to get reading sessions by book', e);
    }
  }

  @override
  Future<List<ReadingSession>> getReadingSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.readingSessionsTable,
        where: 'session_date >= ? AND session_date <= ?',
        whereArgs: [
          startDate.millisecondsSinceEpoch,
          endDate.millisecondsSinceEpoch,
        ],
        orderBy: 'session_date DESC',
      );

      return maps.map((map) => _mapToReadingSession(map)).toList();
    } catch (e) {
      throw DatabaseOperationException('Failed to get reading sessions by date range', e);
    }
  }

  @override
  Future<int> calculateCurrentStreak() async {
    try {
      final db = await _databaseHelper.database;
      
      // Get all unique reading dates in descending order
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT DISTINCT DATE(session_date / 1000, 'unixepoch') as reading_date
        FROM ${DatabaseHelper.readingSessionsTable}
        ORDER BY reading_date DESC
      ''');

      if (maps.isEmpty) return 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      int streak = 0;
      DateTime? lastReadingDate;

      for (final map in maps) {
        final readingDate = DateTime.parse(map['reading_date']);
        
        if (lastReadingDate == null) {
          // First iteration - check if it's today or yesterday
          if (_isSameDay(readingDate, today) || _isSameDay(readingDate, yesterday)) {
            streak = 1;
            lastReadingDate = readingDate;
          } else {
            // If the most recent reading is not today or yesterday, streak is 0
            break;
          }
        } else {
          // Check if this date is consecutive to the last reading date
          final expectedDate = lastReadingDate.subtract(const Duration(days: 1));
          if (_isSameDay(readingDate, expectedDate)) {
            streak++;
            lastReadingDate = readingDate;
          } else {
            // Gap found, streak ends
            break;
          }
        }
      }

      return streak;
    } catch (e) {
      throw DatabaseOperationException('Failed to calculate current streak', e);
    }
  }

  @override
  Future<bool> hasReadToday() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

      final sessions = await getReadingSessionsByDateRange(startOfDay, endOfDay);
      return sessions.isNotEmpty;
    } catch (e) {
      throw DatabaseOperationException('Failed to check if user has read today', e);
    }
  }

  @override
  Future<void> updateStreakOnProgress() async {
    try {
      final currentStats = await getUserStats();
      final newStreak = await calculateCurrentStreak();
      
      final updatedStats = currentStats.copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > currentStats.longestStreak 
            ? newStreak 
            : currentStats.longestStreak,
        lastReadingDate: DateTime.now(),
      );

      await updateUserStats(updatedStats);
    } catch (e) {
      throw DatabaseOperationException('Failed to update streak on progress', e);
    }
  }

  @override
  Future<void> resetStreakIfMissed() async {
    try {
      final hasRead = await hasReadToday();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final yesterdayEnd = yesterdayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      
      final yesterdaySessions = await getReadingSessionsByDateRange(yesterdayStart, yesterdayEnd);
      final hasReadYesterday = yesterdaySessions.isNotEmpty;

      // If user hasn't read today and didn't read yesterday, reset streak
      if (!hasRead && !hasReadYesterday) {
        final currentStats = await getUserStats();
        final updatedStats = currentStats.copyWith(currentStreak: 0);
        await updateUserStats(updatedStats);
      }
    } catch (e) {
      throw DatabaseOperationException('Failed to reset streak if missed', e);
    }
  }

  @override
  Future<int> getPagesReadOnDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT SUM(pages_read) as total_pages
        FROM ${DatabaseHelper.readingSessionsTable}
        WHERE session_date >= ? AND session_date <= ?
      ''', [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ]);

      return result.first['total_pages'] as int? ?? 0;
    } catch (e) {
      throw DatabaseOperationException('Failed to get pages read on date', e);
    }
  }

  @override
  Future<List<ReadingSession>> getTodaysSessions() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

      return await getReadingSessionsByDateRange(startOfDay, endOfDay);
    } catch (e) {
      throw DatabaseOperationException('Failed to get today\'s sessions', e);
    }
  }

  /// Update user statistics after logging a reading session
  Future<void> _updateStatsAfterSession(ReadingSession session) async {
    final currentStats = await getUserStats();
    
    // Update total pages read
    final updatedStats = currentStats.copyWith(
      totalPagesRead: currentStats.totalPagesRead + session.pagesRead,
      lastReadingDate: session.sessionDate,
    );

    await updateUserStats(updatedStats);
    
    // Update streak
    await updateStreakOnProgress();
  }

  /// Convert database map to ReadingSession object
  ReadingSession _mapToReadingSession(Map<String, dynamic> map) {
    return ReadingSession(
      id: map['id'] as String,
      bookId: map['book_id'] as String,
      pagesRead: map['pages_read'] as int,
      timeSpent: map['time_spent'] != null 
          ? Duration(minutes: map['time_spent'] as int)
          : null,
      sessionDate: DateTime.fromMillisecondsSinceEpoch(map['session_date'] as int),
    );
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}