import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:reading_companion_app/blocs/book/book_bloc_export.dart';
import 'package:reading_companion_app/models/book.dart';
import 'package:reading_companion_app/models/book_status.dart';
import 'package:reading_companion_app/repositories/book_repository.dart';

import 'book_bloc_test.mocks.dart';

@GenerateMocks([BookRepository])
void main() {
  group('BookBloc', () {
    late MockBookRepository mockBookRepository;

    final testBook1 = Book(
      id: '1',
      title: 'Test Book 1',
      author: 'Test Author 1',
      totalPages: 300,
      pagesRead: 100,
      status: BookStatus.reading,
      createdAt: DateTime(2024, 1, 1),
    );

    final testBook2 = Book(
      id: '2',
      title: 'Test Book 2',
      author: 'Test Author 2',
      totalPages: 250,
      pagesRead: 250,
      status: BookStatus.finished,
      createdAt: DateTime(2024, 1, 2),
      finishedAt: DateTime(2024, 1, 15),
    );

    final testBooks = [testBook1, testBook2];
    final readingBooks = [testBook1];

    setUp(() {
      mockBookRepository = MockBookRepository();
    });

    test('initial state is BookInitial', () {
      final bookBloc = BookBloc(bookRepository: mockBookRepository);
      expect(bookBloc.state, equals(const BookInitial()));
      bookBloc.close();
    });

    group('LoadBooks', () {
      blocTest<BookBloc, BookState>(
        'emits [BookLoading, BookLoaded] when LoadBooks is added successfully',
        build: () {
          when(mockBookRepository.watchAll())
              .thenAnswer((_) => Stream.value(testBooks));
          return BookBloc(bookRepository: mockBookRepository);
        },
        act: (bloc) => bloc.add(const LoadBooks()),
        expect: () => [
          const BookLoading(),
          BookLoaded(testBooks),
        ],
        verify: (_) {
          verify(mockBookRepository.watchAll()).called(1);
        },
      );

      blocTest<BookBloc, BookState>(
        'emits [BookLoading, BookError] when LoadBooks fails',
        build: () {
          when(mockBookRepository.watchAll())
              .thenThrow(Exception('Database error'));
          return BookBloc(bookRepository: mockBookRepository);
        },
        act: (bloc) => bloc.add(const LoadBooks()),
        expect: () => [
          const BookLoading(),
          isA<BookError>()
              .having((state) => state.message, 'message', contains('Failed to load books')),
        ],
      );

      blocTest<BookBloc, BookState>(
        'emits [BookLoading, BookLoaded] with filtered books when filter is active',
        build: () {
          when(mockBookRepository.watchBooksByStatus(BookStatus.reading))
              .thenAnswer((_) => Stream.value(readingBooks));
          return BookBloc(bookRepository: mockBookRepository);
        },
        act: (bloc) => bloc.add(const FilterBooks(BookStatus.reading)),
        expect: () => [
          const BookLoading(),
          BookLoaded(readingBooks, currentFilter: BookStatus.reading),
        ],
        verify: (_) {
          verify(mockBookRepository.watchBooksByStatus(BookStatus.reading)).called(1);
        },
      );
    });

    group('AddBook', () {
      blocTest<BookBloc, BookState>(
        'calls repository.addBook when AddBook is added',
        build: () {
          when(mockBookRepository.watchAll())
              .thenAnswer((_) => Stream.value(testBooks));
          when(mockBookRepository.addBook(any))
              .thenAnswer((_) async {});
          return BookBloc(bookRepository: mockBookRepository);
        },
        seed: () => BookLoaded(testBooks),
        act: (bloc) => bloc.add(AddBook(testBook1)),
        expect: () => [
          BookOperationInProgress(testBooks),
          const BookLoading(),
          BookLoaded(testBooks),
        ],
        verify: (_) {
          verify(mockBookRepository.addBook(testBook1)).called(1);
        },
      );

      blocTest<BookBloc, BookState>(
        'emits BookError when addBook fails',
        build: () {
          when(mockBookRepository.addBook(any))
              .thenThrow(Exception('Add book failed'));
          return BookBloc(bookRepository: mockBookRepository);
        },
        seed: () => BookLoaded(testBooks),
        act: (bloc) => bloc.add(AddBook(testBook1)),
        expect: () => [
          BookOperationInProgress(testBooks),
          isA<BookError>()
              .having((state) => state.message, 'message', contains('Failed to add book')),
        ],
      );
    });

    group('UpdateBook', () {
      blocTest<BookBloc, BookState>(
        'calls repository.updateBook when UpdateBook is added',
        build: () {
          when(mockBookRepository.watchAll())
              .thenAnswer((_) => Stream.value(testBooks));
          when(mockBookRepository.updateBook(any))
              .thenAnswer((_) async {});
          return BookBloc(bookRepository: mockBookRepository);
        },
        seed: () => BookLoaded(testBooks),
        act: (bloc) {
          final updatedBook = testBook1.copyWith(pagesRead: 150);
          bloc.add(UpdateBook(updatedBook));
        },
        expect: () => [
          BookOperationInProgress(testBooks),
          const BookLoading(),
          BookLoaded(testBooks),
        ],
        verify: (_) {
          verify(mockBookRepository.updateBook(any)).called(1);
        },
      );

      blocTest<BookBloc, BookState>(
        'emits BookError when updateBook fails',
        build: () {
          when(mockBookRepository.updateBook(any))
              .thenThrow(Exception('Update book failed'));
          return BookBloc(bookRepository: mockBookRepository);
        },
        seed: () => BookLoaded(testBooks),
        act: (bloc) => bloc.add(UpdateBook(testBook1)),
        expect: () => [
          BookOperationInProgress(testBooks),
          isA<BookError>()
              .having((state) => state.message, 'message', contains('Failed to update book')),
        ],
      );
    });

    group('DeleteBook', () {
      blocTest<BookBloc, BookState>(
        'calls repository.deleteBook when DeleteBook is added',
        build: () {
          when(mockBookRepository.watchAll())
              .thenAnswer((_) => Stream.value(testBooks));
          when(mockBookRepository.deleteBook(any))
              .thenAnswer((_) async {});
          return BookBloc(bookRepository: mockBookRepository);
        },
        seed: () => BookLoaded(testBooks),
        act: (bloc) => bloc.add(const DeleteBook('1')),
        expect: () => [
          BookOperationInProgress(testBooks),
          const BookLoading(),
          BookLoaded(testBooks),
        ],
        verify: (_) {
          verify(mockBookRepository.deleteBook('1')).called(1);
        },
      );

      blocTest<BookBloc, BookState>(
        'emits BookError when deleteBook fails',
        build: () {
          when(mockBookRepository.deleteBook(any))
              .thenThrow(Exception('Delete book failed'));
          return BookBloc(bookRepository: mockBookRepository);
        },
        seed: () => BookLoaded(testBooks),
        act: (bloc) => bloc.add(const DeleteBook('1')),
        expect: () => [
          BookOperationInProgress(testBooks),
          isA<BookError>()
              .having((state) => state.message, 'message', contains('Failed to delete book')),
        ],
      );
    });

    group('FilterBooks', () {
      blocTest<BookBloc, BookState>(
        'emits [BookLoading, BookLoaded] with filtered books when FilterBooks is added',
        build: () {
          when(mockBookRepository.watchBooksByStatus(BookStatus.reading))
              .thenAnswer((_) => Stream.value(readingBooks));
          return BookBloc(bookRepository: mockBookRepository);
        },
        act: (bloc) => bloc.add(const FilterBooks(BookStatus.reading)),
        expect: () => [
          const BookLoading(),
          BookLoaded(readingBooks, currentFilter: BookStatus.reading),
        ],
        verify: (_) {
          verify(mockBookRepository.watchBooksByStatus(BookStatus.reading)).called(1);
        },
      );

      blocTest<BookBloc, BookState>(
        'emits [BookLoading, BookLoaded] with all books when FilterBooks is added with null',
        build: () {
          when(mockBookRepository.watchAll())
              .thenAnswer((_) => Stream.value(testBooks));
          return BookBloc(bookRepository: mockBookRepository);
        },
        act: (bloc) => bloc.add(const FilterBooks(null)),
        expect: () => [
          const BookLoading(),
          BookLoaded(testBooks, currentFilter: null),
        ],
        verify: (_) {
          verify(mockBookRepository.watchAll()).called(1);
        },
      );

      blocTest<BookBloc, BookState>(
        'emits BookError when filtering fails',
        build: () {
          when(mockBookRepository.watchBooksByStatus(any))
              .thenThrow(Exception('Filter failed'));
          return BookBloc(bookRepository: mockBookRepository);
        },
        act: (bloc) => bloc.add(const FilterBooks(BookStatus.reading)),
        expect: () => [
          const BookLoading(),
          isA<BookError>()
              .having((state) => state.message, 'message', contains('Failed to filter books')),
        ],
      );
    });

    group('Stream subscription management', () {
      test('cancels subscription on close', () async {
        when(mockBookRepository.watchAll())
            .thenAnswer((_) => Stream.value(testBooks));
        
        final bookBloc = BookBloc(bookRepository: mockBookRepository);
        bookBloc.add(const LoadBooks());
        await Future.delayed(const Duration(milliseconds: 10));
        
        await bookBloc.close();
        
        // Verify that the stream subscription is properly cancelled
        expect(bookBloc.isClosed, isTrue);
      });

      test('cancels previous subscription when new LoadBooks is added', () async {
        when(mockBookRepository.watchAll())
            .thenAnswer((_) => Stream.value(testBooks));
        
        final bookBloc = BookBloc(bookRepository: mockBookRepository);
        
        // First load
        bookBloc.add(const LoadBooks());
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Second load should cancel the first subscription
        bookBloc.add(const LoadBooks());
        await Future.delayed(const Duration(milliseconds: 10));
        
        verify(mockBookRepository.watchAll()).called(2);
        
        await bookBloc.close();
      });
    });

    group('State transitions', () {
      test('BookLoaded copyWith works correctly', () {
        const originalState = BookLoaded([]);
        final newBooks = [testBook1];
        
        final newState = originalState.copyWith(books: newBooks);
        
        expect(newState.books, equals(newBooks));
        expect(newState.currentFilter, equals(originalState.currentFilter));
      });

      test('BookLoaded equality works correctly', () {
        const state1 = BookLoaded([]);
        const state2 = BookLoaded([]);
        final state3 = BookLoaded([testBook1]);
        
        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
      });

      test('BookError contains proper error information', () {
        const errorMessage = 'Test error';
        final exception = Exception('Test exception');
        final errorState = BookError(errorMessage, exception: exception);
        
        expect(errorState.message, equals(errorMessage));
        expect(errorState.exception, equals(exception));
      });
    });
  });
}