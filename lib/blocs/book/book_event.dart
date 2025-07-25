import 'package:equatable/equatable.dart';
import '../../models/book.dart';
import '../../models/book_status.dart';

/// Base class for all book-related events
abstract class BookEvent extends Equatable {
  const BookEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all books
class LoadBooks extends BookEvent {
  const LoadBooks();
}

/// Event to add a new book
class AddBook extends BookEvent {
  final Book book;

  const AddBook(this.book);

  @override
  List<Object?> get props => [book];
}

/// Event to update an existing book
class UpdateBook extends BookEvent {
  final Book book;

  const UpdateBook(this.book);

  @override
  List<Object?> get props => [book];
}

/// Event to delete a book
class DeleteBook extends BookEvent {
  final String bookId;

  const DeleteBook(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

/// Event to filter books by status
class FilterBooks extends BookEvent {
  final BookStatus? status;

  const FilterBooks(this.status);

  @override
  List<Object?> get props => [status];
}