import 'package:equatable/equatable.dart';
import '../../models/book.dart';
import '../../models/book_status.dart';

/// Base class for all book-related states
abstract class BookState extends Equatable {
  const BookState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the BLoC is first created
class BookInitial extends BookState {
  const BookInitial();
}

/// State when books are being loaded
class BookLoading extends BookState {
  const BookLoading();
}

/// State when books have been successfully loaded
class BookLoaded extends BookState {
  final List<Book> books;
  final BookStatus? currentFilter;

  const BookLoaded(this.books, {this.currentFilter});

  @override
  List<Object?> get props => [books, currentFilter];

  BookLoaded copyWith({
    List<Book>? books,
    BookStatus? currentFilter,
  }) {
    return BookLoaded(
      books ?? this.books,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

/// State when an error occurs
class BookError extends BookState {
  final String message;
  final Exception? exception;

  const BookError(this.message, {this.exception});

  @override
  List<Object?> get props => [message, exception];
}

/// State when a book operation (add/update/delete) is in progress
class BookOperationInProgress extends BookState {
  final List<Book> books;
  final BookStatus? currentFilter;

  const BookOperationInProgress(this.books, {this.currentFilter});

  @override
  List<Object?> get props => [books, currentFilter];
}