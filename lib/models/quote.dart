class Quote {
  final String id;
  final String bookId;
  final String text;
  final int? pageNumber;
  final DateTime createdAt;

  const Quote({
    required this.id,
    required this.bookId,
    required this.text,
    this.pageNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'text': text,
      'pageNumber': pageNumber,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      text: json['text'] as String,
      pageNumber: json['pageNumber'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  Quote copyWith({
    String? id,
    String? bookId,
    String? text,
    int? pageNumber,
    DateTime? createdAt,
  }) {
    return Quote(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      text: text ?? this.text,
      pageNumber: pageNumber ?? this.pageNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Quote &&
        other.id == id &&
        other.bookId == bookId &&
        other.text == text &&
        other.pageNumber == pageNumber &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, bookId, text, pageNumber, createdAt);
  }

  @override
  String toString() {
    return 'Quote(id: $id, bookId: $bookId, text: $text, pageNumber: $pageNumber, createdAt: $createdAt)';
  }
}