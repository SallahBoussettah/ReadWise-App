import '../models/user_stats.dart';
import '../models/reading_session.dart';

/// Repository interface for user statistics and reading sessions
abstract class UserRepository {
  /// Get current user statistics
  Future<UserStats> getUserStats();

  /// Update user statistics
  Future<void> updateUserStats(UserStats stats);

  /// Log a new reading session
  Future<void> logReadingSession(ReadingSession session);

  /// Get all reading sessions
  Future<List<ReadingSession>> getReadingSessions();

  /// Get reading sessions for a specific book
  Future<List<ReadingSession>> getReadingSessionsByBook(String bookId);

  /// Get reading sessions for a specific date range
  Future<List<ReadingSession>> getReadingSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Calculate current reading streak
  Future<int> calculateCurrentStreak();

  /// Check if user has read today
  Future<bool> hasReadToday();

  /// Update streak after logging reading progress
  Future<void> updateStreakOnProgress();

  /// Reset streak if user missed a day
  Future<void> resetStreakIfMissed();

  /// Get total pages read for a specific date
  Future<int> getPagesReadOnDate(DateTime date);

  /// Get reading sessions for today
  Future<List<ReadingSession>> getTodaysSessions();
}