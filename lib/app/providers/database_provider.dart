import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noctrafit/data/local/db/app_database.dart';

/// Provider for the main database instance.
/// This is a singleton that will be initialized once and reused throughout the app.
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
