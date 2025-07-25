import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/book.dart';
import '../../models/book_status.dart';
import '../../repositories/book_repository.dart';
import 'book_event.dart';
import 'book_state.dart';

/// BLoC for managing book-related state and operations
class BookBloc extends Bloc<BookEvent, BookState> {
  final BookRepository _bookRepository;
  BookStatus? _currentFilter;

  BookBloc({required BookRepository bookRepository})
      : _bookRepository = bookRepository,
        super(const BookInitial()) {
    on<LoadBooks>(_onLoadBooks);
    on<AddBook>(_onAddBook);
    on<UpdateBook>(_onUpdateBook);
    on<DeleteBook>(_onDeleteBook);
    on<FilterBooks>(_onFilterBooks);
  }

  /// Handle loading books
  Future<void> _onLoadBooks(LoadBooks event, Emitter<BookState> emit) async {
    try {
      emit(const BookLoading());
      
      // Use emit.forEach to properly handle stream emissions
      final stream = _currentFilter != null
          ? _bookRepository.watchBooksByStatus(_currentFilter!)
          : _bookRepository.watchAll();
      
      await emit.forEach<List<Book>>(
        stream,
        onData: (books) => BookLoaded(books, currentFilter: _currentFilter),
        onError: (error, stackTrace) => BookError(
          'Failed to load books: ${error.toString()}',
          exception: error is Exception ? error : Exception(error.toString()),
        ),
      );
    } catch (e) {
      emit(BookError('Failed to load books: ${e.toString()}', exception: e is Exception ? e : Exception(e.toString())));
    }
  }

  /// Handle adding a new book
  Future<void> _onAddBook(AddBook event, Emitter<BookState> emit) async {
    try {
      // Show operation in progress if we have current books
      if (state is BookLoaded) {
        final currentState = state as BookLoaded;
        emit(BookOperationInProgress(currentState.books, currentFilter: currentState.currentFilter));
      }

      await _bookRepository.addBook(event.book);
      
      // Reload books to get updated state
      add(const LoadBooks());
    } catch (e) {
      emit(BookError('Failed to add book: ${e.toString()}', exception: e is Exception ? e : Exception(e.toString())));
    }
  }

  /// Handle updating an existing book
  Future<void> _onUpdateBook(UpdateBook event, Emitter<BookState> emit) async {
    try {
      // Show operation in progress if we have current books
      if (state is BookLoaded) {
        final currentState = state as BookLoaded;
        emit(BookOperationInProgress(currentState.books, currentFilter: currentState.currentFilter));
      }

      await _bookRepository.updateBook(event.book);
      
      // Reload books to get updated state
      add(const LoadBooks());
    } catch (e) {
      emit(BookError('Failed to update book: ${e.toString()}', exception: e is Exception ? e : Exception(e.toString())));
    }
  }

  /// Handle deleting a book
  Future<void> _onDeleteBook(DeleteBook event, Emitter<BookState> emit) async {
    try {
      // Show operation in progress if we have current books
      if (state is BookLoaded) {
        final currentState = state as BookLoaded;
        emit(BookOperationInProgress(currentState.books, currentFilter: currentState.currentFilter));
      }

      await _bookRepository.deleteBook(event.bookId);
      
      // Reload books to get updated state
      add(const LoadBooks());
    } catch (e) {
      emit(BookError('Failed to delete book: ${e.toString()}', exception: e is Exception ? e : Exception(e.toString())));
    }
  }

  /// Handle filtering books by status
  Future<void> _onFilterBooks(FilterBooks event, Emitter<BookState> emit) async {
    try {
      _currentFilter = event.status;
      
      emit(const BookLoading());
      
      // Use emit.forEach to properly handle stream emissions
      final stream = _currentFilter != null
          ? _bookRepository.watchBooksByStatus(_currentFilter!)
          : _bookRepository.watchAll();
      
      await emit.forEach<List<Book>>(
        stream,
        onData: (books) => BookLoaded(books, currentFilter: _currentFilter),
        onError: (error, stackTrace) => BookError(
          'Failed to filter books: ${error.toString()}',
          exception: error is Exception ? error : Exception(error.toString()),
        ),
      );
    } catch (e) {
      emit(BookError('Failed to filter books: ${e.toString()}', exception: e is Exception ? e : Exception(e.toString())));
    }
  }


}