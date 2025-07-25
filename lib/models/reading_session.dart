class ReadingSession {
  final String id;
  final String bookId;
  final int pagesRead;
  final Duration? timeSpent;
  final DateTime sessionDate;

  const ReadingSession({
    required this.id,
    required this.bookId,
    required this.pagesRead,
    this.timeSpent,
    required this.sessionDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'pagesRead': pagesRead,
      'timeSpent': timeSpent?.inMinutes,
      'sessionDate': sessionDate.millisecondsSinceEpoch,
    };
  }

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      pagesRead: json['pagesRead'] as int,
      timeSpent: json['timeSpent'] != null 
          ? Duration(minutes: json['timeSpent'] as int)
          : null,
      sessionDate: DateTime.fromMillisecondsSinceEpoch(json['sessionDate'] as int),
    );
  }

  ReadingSession copyWith({
    String? id,
    String? bookId,
    int? pagesRead,
    Duration? timeSpent,
    DateTime? sessionDate,
  }) {
    return ReadingSession(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      pagesRead: pagesRead ?? this.pagesRead,
      timeSpent: timeSpent ?? this.timeSpent,
      sessionDate: sessionDate ?? this.sessionDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingSession &&
        other.id == id &&
        other.bookId == bookId &&
        other.pagesRead == pagesRead &&
        other.timeSpent == timeSpent &&
        other.sessionDate == sessionDate;
  }

  @override
  int get hashCode {
    return Object.hash(id, bookId, pagesRead, timeSpent, sessionDate);
  }

  @override
  String toString() {
    return 'ReadingSession(id: $id, bookId: $bookId, pagesRead: $pagesRead, timeSpent: $timeSpent, sessionDate: $sessionDate)';
  }
}