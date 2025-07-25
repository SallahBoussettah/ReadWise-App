import 'package:flutter_test/flutter_test.dart';
import 'package:reading_companion_app/repositories/repositories.dart';

void main() {
  group('Repository Exceptions', () {
    test('RepositoryException should format message correctly', () {
      const exception = RepositoryException('Test message');
      expect(exception.toString(), equals('RepositoryException: Test message'));
    });

    test('RepositoryException should include cause', () {
      final cause = Exception('Root cause');
      final exception = RepositoryException('Test message', cause);
      expect(exception.toString(), contains('Test message'));
      expect(exception.toString(), contains('Caused by: Exception: Root cause'));
    });

    test('EntityNotFoundException should format message correctly', () {
      final exception = EntityNotFoundException('Book', 'book123');
      expect(exception.toString(), equals('RepositoryException: Book with id book123 not found'));
    });

    test('DuplicateEntityException should format message correctly', () {
      final exception = DuplicateEntityException('Book', 'book123');
      expect(exception.toString(), equals('RepositoryException: Book with id book123 already exists'));
    });

    test('DatabaseOperationException should format message correctly', () {
      final exception = DatabaseOperationException('insert');
      expect(exception.toString(), equals('RepositoryException: Database operation failed: insert'));
    });

    test('DatabaseOperationException should include cause', () {
      final cause = Exception('SQL error');
      final exception = DatabaseOperationException('insert', cause);
      expect(exception.toString(), contains('Database operation failed: insert'));
      expect(exception.toString(), contains('Caused by: Exception: SQL error'));
    });
  });
}