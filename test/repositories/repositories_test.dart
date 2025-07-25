import 'package:flutter_test/flutter_test.dart';

import 'base_repository_test.dart' as base_repository_test;
import 'database_helper_test.dart' as database_helper_test;
import 'database_migration_test.dart' as database_migration_test;
import 'sqlite_repository_test.dart' as sqlite_repository_test;

void main() {
  group('Repository Tests', () {
    group('Base Repository', base_repository_test.main);
    group('Database Helper', database_helper_test.main);
    group('Database Migration', database_migration_test.main);
    group('SQLite Repository', sqlite_repository_test.main);
  });
}