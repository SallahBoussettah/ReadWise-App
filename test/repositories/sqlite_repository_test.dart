import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reading_companion_app/repositories/repositories.dart';

// Test entity for repository testing
class TestEntity {
  final String id;
  final String name;
  final int value;

  const TestEntity({
    required this.id,
    required this.name,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'value': value,
    };
  }

  factory TestEntity.fromMap(Map<String, dynamic> map) {
    return TestEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      value: map['value'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestEntity &&
        other.id == id &&
        other.name == name &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(id, name, value);
}

// Test repository implementation
class TestRepository extends SQLiteRepository<TestEntity, String> {
  TestRepository(DatabaseHelper databaseHelper) : super(databaseHelper);

  @override
  String get tableName => 'test_entities';

  @override
  TestEntity fromMap(Map<String, dynamic> map) => TestEntity.fromMap(map);

  @override
  Map<String, dynamic> toMap(TestEntity entity) => entity.toMap();

  @override
  String getId(TestEntity entity) => entity.id;
}

// Mock DatabaseHelper for testing
class MockDatabaseHelper implements DatabaseHelper {
  late Database _mockDatabase;

  void setMockDatabase(Database database) {
    _mockDatabase = database;
  }

  @override
  Future<Database> get database async => _mockDatabase;

  // Implement other required methods as no-ops for testing
  @override
  Future<void> close() async {}

  @override
  Future<void> deleteDatabase() async {}

  @override
  Future<bool> databaseExists() async => true;

  @override
  Future<String> getDatabasePath() async => ':memory:';

  @override
  MigrationManager get migrationManager => MigrationManager();
}

void main() {
  late Database database;
  late MockDatabaseHelper mockDatabaseHelper;
  late TestRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );

    // Create test table
    await database.execute('''
      CREATE TABLE test_entities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        value INTEGER NOT NULL
      )
    ''');

    mockDatabaseHelper = MockDatabaseHelper();
    mockDatabaseHelper.setMockDatabase(database);
    repository = TestRepository(mockDatabaseHelper);
  });

  tearDown(() async {
    repository.dispose();
    await database.close();
  });

  group('SQLiteRepository', () {
    test('should insert entity successfully', () async {
      const entity = TestEntity(id: '1', name: 'Test', value: 42);

      await repository.insert(entity);

      final result = await repository.getById('1');
      expect(result, equals(entity));
    });

    test('should throw DuplicateEntityException when inserting duplicate', () async {
      const entity = TestEntity(id: '1', name: 'Test', value: 42);

      await repository.insert(entity);

      expect(
        () async => await repository.insert(entity),
        throwsA(isA<DuplicateEntityException>()),
      );
    });

    test('should get all entities', () async {
      const entity1 = TestEntity(id: '1', name: 'Test1', value: 1);
      const entity2 = TestEntity(id: '2', name: 'Test2', value: 2);

      await repository.insert(entity1);
      await repository.insert(entity2);

      final result = await repository.getAll();
      expect(result.length, equals(2));
      expect(result, containsAll([entity1, entity2]));
    });

    test('should get entity by id', () async {
      const entity = TestEntity(id: '1', name: 'Test', value: 42);

      await repository.insert(entity);

      final result = await repository.getById('1');
      expect(result, equals(entity));
    });

    test('should return null when entity not found', () async {
      final result = await repository.getById('nonexistent');
      expect(result, isNull);
    });

    test('should update entity successfully', () async {
      const originalEntity = TestEntity(id: '1', name: 'Test', value: 42);
      const updatedEntity = TestEntity(id: '1', name: 'Updated', value: 100);

      await repository.insert(originalEntity);
      await repository.update(updatedEntity);

      final result = await repository.getById('1');
      expect(result, equals(updatedEntity));
    });

    test('should throw EntityNotFoundException when updating non-existent entity', () async {
      const entity = TestEntity(id: 'nonexistent', name: 'Test', value: 42);

      expect(
        () async => await repository.update(entity),
        throwsA(isA<EntityNotFoundException>()),
      );
    });

    test('should delete entity successfully', () async {
      const entity = TestEntity(id: '1', name: 'Test', value: 42);

      await repository.insert(entity);
      await repository.delete('1');

      final result = await repository.getById('1');
      expect(result, isNull);
    });

    test('should throw EntityNotFoundException when deleting non-existent entity', () async {
      expect(
        () async => await repository.delete('nonexistent'),
        throwsA(isA<EntityNotFoundException>()),
      );
    });

    test('should check if entity exists', () async {
      const entity = TestEntity(id: '1', name: 'Test', value: 42);

      expect(await repository.exists('1'), isFalse);

      await repository.insert(entity);

      expect(await repository.exists('1'), isTrue);
    });

    test('should count entities', () async {
      expect(await repository.count(), equals(0));

      const entity1 = TestEntity(id: '1', name: 'Test1', value: 1);
      const entity2 = TestEntity(id: '2', name: 'Test2', value: 2);

      await repository.insert(entity1);
      expect(await repository.count(), equals(1));

      await repository.insert(entity2);
      expect(await repository.count(), equals(2));
    });

    test('should clear all entities', () async {
      const entity1 = TestEntity(id: '1', name: 'Test1', value: 1);
      const entity2 = TestEntity(id: '2', name: 'Test2', value: 2);

      await repository.insert(entity1);
      await repository.insert(entity2);

      expect(await repository.count(), equals(2));

      await repository.clear();

      expect(await repository.count(), equals(0));
    });

    test('should execute custom query', () async {
      const entity1 = TestEntity(id: '1', name: 'Test1', value: 10);
      const entity2 = TestEntity(id: '2', name: 'Test2', value: 20);

      await repository.insert(entity1);
      await repository.insert(entity2);

      final result = await repository.query(
        where: 'value > ?',
        whereArgs: [15],
      );

      expect(result.length, equals(1));
      expect(result.first['id'], equals('2'));
    });

    test('should execute raw query', () async {
      const entity = TestEntity(id: '1', name: 'Test', value: 42);

      await repository.insert(entity);

      final result = await repository.rawQuery(
        'SELECT * FROM test_entities WHERE name = ?',
        ['Test'],
      );

      expect(result.length, equals(1));
      expect(result.first['id'], equals('1'));
    });

    test('should provide streaming functionality', () async {
      const entity1 = TestEntity(id: '1', name: 'Test1', value: 1);
      const entity2 = TestEntity(id: '2', name: 'Test2', value: 2);

      final stream = repository.watchAll();
      final streamData = <List<TestEntity>>[];

      final subscription = stream.listen((data) {
        streamData.add(data);
      });

      // Wait for initial empty data
      await Future.delayed(const Duration(milliseconds: 10));

      await repository.insert(entity1);
      await Future.delayed(const Duration(milliseconds: 10));

      await repository.insert(entity2);
      await Future.delayed(const Duration(milliseconds: 10));

      await subscription.cancel();

      expect(streamData.length, greaterThanOrEqualTo(2));
      expect(streamData.last.length, equals(2));
      expect(streamData.last, containsAll([entity1, entity2]));
    });

    test('should watch entity by id', () async {
      const entity = TestEntity(id: '1', name: 'Test', value: 42);

      final stream = repository.watchById('1');
      TestEntity? streamData;

      final subscription = stream.listen((data) {
        streamData = data;
      });

      await Future.delayed(const Duration(milliseconds: 10));

      await repository.insert(entity);
      await Future.delayed(const Duration(milliseconds: 10));

      await subscription.cancel();

      expect(streamData, equals(entity));
    });

    test('should handle database operation exceptions', () async {
      // Close the database to simulate error
      await database.close();

      expect(
        () async => await repository.getAll(),
        throwsA(isA<DatabaseOperationException>()),
      );
    });
  });
}