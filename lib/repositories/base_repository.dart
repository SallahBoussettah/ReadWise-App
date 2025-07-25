import 'dart:async';

/// Base repository interface that defines common CRUD operations
abstract class BaseRepository<T, ID> {
  /// Get all entities
  Future<List<T>> getAll();

  /// Get entity by ID
  Future<T?> getById(ID id);

  /// Insert a new entity
  Future<void> insert(T entity);

  /// Update an existing entity
  Future<void> update(T entity);

  /// Delete entity by ID
  Future<void> delete(ID id);

  /// Check if entity exists by ID
  Future<bool> exists(ID id);

  /// Get count of all entities
  Future<int> count();

  /// Clear all entities
  Future<void> clear();
}

/// Base repository interface with streaming capabilities
abstract class StreamableRepository<T, ID> extends BaseRepository<T, ID> {
  /// Watch all entities as a stream
  Stream<List<T>> watchAll();

  /// Watch entity by ID as a stream
  Stream<T?> watchById(ID id);
}

/// Exception thrown when a repository operation fails
class RepositoryException implements Exception {
  final String message;
  final dynamic cause;

  const RepositoryException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'RepositoryException: $message\nCaused by: $cause';
    }
    return 'RepositoryException: $message';
  }
}

/// Exception thrown when an entity is not found
class EntityNotFoundException extends RepositoryException {
  EntityNotFoundException(String entityType, dynamic id)
      : super('$entityType with id $id not found');
}

/// Exception thrown when trying to insert a duplicate entity
class DuplicateEntityException extends RepositoryException {
  DuplicateEntityException(String entityType, dynamic id)
      : super('$entityType with id $id already exists');
}

/// Exception thrown when database operation fails
class DatabaseOperationException extends RepositoryException {
  DatabaseOperationException(String operation, [dynamic cause])
      : super('Database operation failed: $operation', cause);
}