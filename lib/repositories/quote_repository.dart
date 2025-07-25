import 'dart:async';
import '../models/quote.dart';
import 'base_repository.dart';

/// Repository interface for quote-related operations
abstract class QuoteRepository extends StreamableRepository<Quote, String> {
  /// Get all quotes
  @override
  Future<List<Quote>> getAll();

  /// Get quotes filtered by book ID
  Future<List<Quote>> getQuotesByBook(String bookId);

  /// Get a quote by its ID
  @override
  Future<Quote?> getById(String id);

  /// Add a new quote
  Future<void> addQuote(Quote quote);

  /// Update an existing quote
  Future<void> updateQuote(Quote quote);

  /// Delete a quote by ID
  Future<void> deleteQuote(String id);

  /// Get a random quote for quote of the day functionality
  Future<Quote?> getRandomQuote();

  /// Watch all quotes as a stream
  @override
  Stream<List<Quote>> watchAll();

  /// Watch quotes filtered by book ID as a stream
  Stream<List<Quote>> watchQuotesByBook(String bookId);

  /// Watch a specific quote by ID as a stream
  @override
  Stream<Quote?> watchById(String id);

  /// Get all quotes (alias for getAll for consistency with task requirements)
  Future<List<Quote>> getAllQuotes() => getAll();
}