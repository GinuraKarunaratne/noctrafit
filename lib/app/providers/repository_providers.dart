import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noctrafit/app/providers/auth_provider.dart';
import 'package:noctrafit/app/providers/database_provider.dart';
import 'package:noctrafit/app/providers/service_providers.dart';
import 'package:noctrafit/data/repositories/insights_repository.dart';
import 'package:noctrafit/data/repositories/preferences_repository.dart';
import 'package:noctrafit/data/repositories/schedule_repository.dart';
import 'package:noctrafit/data/repositories/session_repository.dart';
import 'package:noctrafit/data/repositories/sets_repository.dart';

/// Provider for SetsRepository - handles workout sets data
final setsRepositoryProvider = Provider<SetsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SetsRepository(
    db.workoutSetsDao,
    db.syncQueueDao,
  );
});

/// Provider for ScheduleRepository - handles workout scheduling
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final userRemote = ref.watch(userRemoteDataSourceProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return ScheduleRepository(
    db.scheduleDao,
    userRemote: userRemote,
    auth: auth,
  );
});

/// Provider for SessionRepository - handles active workout sessions
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final userRemote = ref.watch(userRemoteDataSourceProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return SessionRepository(
    db.activeSessionDao,
    db.completionLogsDao,
    userRemote: userRemote,
    auth: auth,
  );
});

/// Provider for InsightsRepository - handles analytics and statistics
final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return InsightsRepository(
    db.completionLogsDao,
  );
});

/// Provider for PreferencesRepository - handles app preferences and settings
final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PreferencesRepository(
    db.preferencesDao,
  );
});
