import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noctrafit/app/providers/repository_providers.dart';
import 'package:noctrafit/data/local/db/app_database.dart';

/// Provider that streams the current active workout session (if any)
/// Returns null if no session is active
final activeSessionProvider = StreamProvider<ActiveSession?>((ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  return sessionRepo.watchActiveSession();
});

/// Provider to check if an active session exists
final hasActiveSessionProvider = Provider<bool>((ref) {
  final session = ref.watch(activeSessionProvider).value;
  return session != null;
});

/// Provider for the active session's UUID (if exists)
final activeSessionUuidProvider = Provider<String?>((ref) {
  final session = ref.watch(activeSessionProvider).value;
  return session?.sessionUuid;
});
