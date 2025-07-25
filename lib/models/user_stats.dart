class UserStats {
  final int currentStreak;
  final int longestStreak;
  final int totalBooksRead;
  final int totalPagesRead;
  final DateTime? lastReadingDate;

  const UserStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalBooksRead,
    required this.totalPagesRead,
    this.lastReadingDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_books_read': totalBooksRead,
      'total_pages_read': totalPagesRead,
      'last_reading_date': lastReadingDate?.millisecondsSinceEpoch,
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      totalBooksRead: json['total_books_read'] as int,
      totalPagesRead: json['total_pages_read'] as int,
      lastReadingDate: json['last_reading_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_reading_date'] as int)
          : null,
    );
  }

  factory UserStats.empty() {
    return const UserStats(
      currentStreak: 0,
      longestStreak: 0,
      totalBooksRead: 0,
      totalPagesRead: 0,
      lastReadingDate: null,
    );
  }

  UserStats copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalBooksRead,
    int? totalPagesRead,
    DateTime? lastReadingDate,
  }) {
    return UserStats(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalBooksRead: totalBooksRead ?? this.totalBooksRead,
      totalPagesRead: totalPagesRead ?? this.totalPagesRead,
      lastReadingDate: lastReadingDate ?? this.lastReadingDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStats &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.totalBooksRead == totalBooksRead &&
        other.totalPagesRead == totalPagesRead &&
        other.lastReadingDate == lastReadingDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentStreak,
      longestStreak,
      totalBooksRead,
      totalPagesRead,
      lastReadingDate,
    );
  }

  @override
  String toString() {
    return 'UserStats(currentStreak: $currentStreak, longestStreak: $longestStreak, totalBooksRead: $totalBooksRead, totalPagesRead: $totalPagesRead, lastReadingDate: $lastReadingDate)';
  }
}