import 'dart:async';
import '../models/book.dart';
import '../models/book_status.dart';
import 'base_repository.dart';

/// Repository interface for book-related operations
abstract class BookRepository extends StreamableRepository<Book, String> {
  /// Get all books in the library
  @override
  Future<List<Book>> getAll();

  /// Get books filtered by status
  Future<List<Book>> getBooksByStatus(BookStatus status);

  /// Get a book by its ID
  @override
  Future<Book?> getById(String id);

  /// Add a new book to the library
  Future<void> addBook(Book book);

  /// Update an existing book
  Future<void> updateBook(Book book);

  /// Delete a book by ID
  Future<void> deleteBook(String id);

  /// Watch all books as a stream
  @override
  Stream<List<Book>> watchAll();

  /// Watch books filtered by status as a stream
  Stream<List<Book>> watchBooksByStatus(BookStatus status);

  /// Watch a specific book by ID as a stream
  @override
  Stream<Book?> watchById(String id);

  /// Get all books (alias for getAll for consistency with task requirements)
  Future<List<Book>> getAllBooks() => getAll();
}