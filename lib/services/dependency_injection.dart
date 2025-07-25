import 'package:get_it/get_it.dart';

/// Global service locator instance
final GetIt getIt = GetIt.instance;

/// Initialize all dependencies for the application
Future<void> setupDependencies() async {
  // TODO: Register repositories when they are implemented
  // TODO: Register services when they are implemented
  // TODO: Register BLoCs when they are implemented
  
  // This will be populated as we implement other tasks
  // For now, we just initialize the container
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}