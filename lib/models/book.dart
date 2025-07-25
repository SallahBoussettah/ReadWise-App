import 'book_status.dart';
import 'quote.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final int totalPages;
  final int pagesRead;
  final BookStatus status;
  final DateTime createdAt;
  final DateTime? finishedAt;
  final List<Quote> quotes;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.totalPages,
    this.pagesRead = 0,
    required this.status,
    required this.createdAt,
    this.finishedAt,
    this.quotes = const [],
  });

  double get progressPercentage {
    if (totalPages <= 0) return 0.0;
    return (pagesRead / totalPages).clamp(0.0, 1.0);
  }

  bool get isFinished => status == BookStatus.finished || progressPercentage >= 1.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'totalPages': totalPages,
      'pagesRead': pagesRead,
      'status': status.value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'finishedAt': finishedAt?.millisecondsSinceEpoch,
      'quotes': quotes.map((quote) => quote.toJson()).toList(),
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      coverUrl: json['coverUrl'] as String?,
      totalPages: json['totalPages'] as int,
      pagesRead: json['pagesRead'] as int? ?? 0,
      status: BookStatus.fromString(json['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      finishedAt: json['finishedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['finishedAt'] as int)
          : null,
      quotes: (json['quotes'] as List<dynamic>?)
              ?.map((quoteJson) => Quote.fromJson(quoteJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
    int? totalPages,
    int? pagesRead,
    BookStatus? status,
    DateTime? createdAt,
    DateTime? finishedAt,
    List<Quote>? quotes,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      totalPages: totalPages ?? this.totalPages,
      pagesRead: pagesRead ?? this.pagesRead,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      finishedAt: finishedAt ?? this.finishedAt,
      quotes: quotes ?? this.quotes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book &&
        other.id == id &&
        other.title == title &&
        other.author == author &&
        other.coverUrl == coverUrl &&
        other.totalPages == totalPages &&
        other.pagesRead == pagesRead &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.finishedAt == finishedAt &&
        _listEquals(other.quotes, quotes);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      author,
      coverUrl,
      totalPages,
      pagesRead,
      status,
      createdAt,
      finishedAt,
      Object.hashAll(quotes),
    );
  }

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author, coverUrl: $coverUrl, totalPages: $totalPages, pagesRead: $pagesRead, status: $status, createdAt: $createdAt, finishedAt: $finishedAt, quotes: ${quotes.length} quotes)';
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}