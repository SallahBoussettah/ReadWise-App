import 'package:flutter_test/flutter_test.dart';
import 'package:reading_companion_app/models/user_stats.dart';

void main() {
  group('UserStats', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    
    final testStats = UserStats(
      currentStreak: 7,
      longestStreak: 15,
      totalBooksRead: 25,
      totalPagesRead: 5000,
      lastReadingDate: testDate,
    );

    final testStatsWithoutDate = UserStats(
      currentStreak: 0,
      longestStreak: 5,
      totalBooksRead: 10,
      totalPagesRead: 2000,
    );

    test('should create UserStats with all properties', () {
      expect(testStats.currentStreak, 7);
      expect(testStats.longestStreak, 15);
      expect(testStats.totalBooksRead, 25);
      expect(testStats.totalPagesRead, 5000);
      expect(testStats.lastReadingDate, testDate);
    });

    test('should create UserStats without last reading date', () {
      expect(testStatsWithoutDate.lastReadingDate, null);
    });

    test('should create empty UserStats', () {
      final emptyStats = UserStats.empty();
      
      expect(emptyStats.currentStreak, 0);
      expect(emptyStats.longestStreak, 0);
      expect(emptyStats.totalBooksRead, 0);
      expect(emptyStats.totalPagesRead, 0);
      expect(emptyStats.lastReadingDate, null);
    });

    test('should serialize to JSON correctly', () {
      final json = testStats.toJson();
      
      expect(json['currentStreak'], 7);
      expect(json['longestStreak'], 15);
      expect(json['totalBooksRead'], 25);
      expect(json['totalPagesRead'], 5000);
      expect(json['lastReadingDate'], testDate.millisecondsSinceEpoch);
    });

    test('should serialize to JSON correctly without last reading date', () {
      final json = testStatsWithoutDate.toJson();
      
      expect(json['lastReadingDate'], null);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'currentStreak': 7,
        'longestStreak': 15,
        'totalBooksRead': 25,
        'totalPagesRead': 5000,
        'lastReadingDate': testDate.millisecondsSinceEpoch,
      };

      final stats = UserStats.fromJson(json);

      expect(stats.currentStreak, 7);
      expect(stats.longestStreak, 15);
      expect(stats.totalBooksRead, 25);
      expect(stats.totalPagesRead, 5000);
      expect(stats.lastReadingDate, testDate);
    });

    test('should deserialize from JSON correctly without last reading date', () {
      final json = {
        'currentStreak': 0,
        'longestStreak': 5,
        'totalBooksRead': 10,
        'totalPagesRead': 2000,
        'lastReadingDate': null,
      };

      final stats = UserStats.fromJson(json);

      expect(stats.lastReadingDate, null);
    });

    test('should create copy with modified properties', () {
      final copy = testStats.copyWith(
        currentStreak: 10,
        totalBooksRead: 30,
      );

      expect(copy.currentStreak, 10);
      expect(copy.longestStreak, testStats.longestStreak);
      expect(copy.totalBooksRead, 30);
      expect(copy.totalPagesRead, testStats.totalPagesRead);
      expect(copy.lastReadingDate, testStats.lastReadingDate);
    });

    test('should maintain equality for identical stats', () {
      final stats1 = UserStats(
        currentStreak: 7,
        longestStreak: 15,
        totalBooksRead: 25,
        totalPagesRead: 5000,
        lastReadingDate: testDate,
      );

      final stats2 = UserStats(
        currentStreak: 7,
        longestStreak: 15,
        totalBooksRead: 25,
        totalPagesRead: 5000,
        lastReadingDate: testDate,
      );

      expect(stats1 == stats2, true);
      expect(stats1.hashCode == stats2.hashCode, true);
    });

    test('should not be equal for different stats', () {
      final stats1 = testStats;
      final stats2 = testStatsWithoutDate;

      expect(stats1 == stats2, false);
    });

    test('should have proper toString representation', () {
      final string = testStats.toString();
      
      expect(string, contains('UserStats('));
      expect(string, contains('currentStreak: 7'));
      expect(string, contains('longestStreak: 15'));
      expect(string, contains('totalBooksRead: 25'));
      expect(string, contains('totalPagesRead: 5000'));
    });

    test('should handle JSON serialization round trip', () {
      final json = testStats.toJson();
      final deserializedStats = UserStats.fromJson(json);
      
      expect(deserializedStats, testStats);
    });

    test('should handle JSON serialization round trip without date', () {
      final json = testStatsWithoutDate.toJson();
      final deserializedStats = UserStats.fromJson(json);
      
      expect(deserializedStats, testStatsWithoutDate);
    });
  });
}