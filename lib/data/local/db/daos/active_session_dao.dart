import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'active_session_dao.g.dart';

@DriftAccessor(tables: [ActiveSessions])
class ActiveSessionDao extends DatabaseAccessor<AppDatabase>
    with _$ActiveSessionDaoMixin {
  ActiveSessionDao(AppDatabase db) : super(db);

  // ========== Get Active Session ==========
  /// Get the current active session (only one row, id=1)
  Future<ActiveSession?> getActiveSession() async {
    return (select(activeSessions)..where((t) => t.id.equals(1))).getSingleOrNull();
  }

  /// Watch the active session (stream)
  Stream<ActiveSession?> watchActiveSession() {
    return (select(activeSessions)..where((t) => t.id.equals(1))).watchSingleOrNull();
  }

  /// Check if there's an active session
  Future<bool> hasActiveSession() async {
    final session = await getActiveSession();
    return session != null && session.isActive;
  }

  // ========== Create/Start Session ==========
  /// Start a new session (replaces any existing session)
  Future<void> startSession(ActiveSessionsCompanion session) async {
    await into(activeSessions).insertOnConflictUpdate(
      session.copyWith(id: const Value(1)), // Always id=1
    );
  }

  // ========== Update Session ==========
  /// Update the entire session
  Future<bool> updateSession(ActiveSession session) async {
    return await update(activeSessions).replace(session);
  }

  /// Update session companion (partial update)
  Future<void> updateSessionCompanion(ActiveSessionsCompanion companion) async {
    await (update(activeSessions)..where((t) => t.id.equals(1)))
        .write(companion.copyWith(lastUpdatedAt: Value(DateTime.now())));
  }

  /// Progress to next exercise
  Future<void> progressToNextExercise() async {
    final session = await getActiveSession();
    if (session == null) return;

    final nextIndex = session.currentExerciseIndex + 1;
    if (nextIndex < session.totalExercises) {
      await updateSessionCompanion(ActiveSessionsCompanion(
        currentExerciseIndex: Value(nextIndex),
      ));
    }
  }

  /// Go to previous exercise
  Future<void> goToPreviousExercise() async {
    final session = await getActiveSession();
    if (session == null) return;

    final prevIndex = session.currentExerciseIndex - 1;
    if (prevIndex >= 0) {
      await updateSessionCompanion(ActiveSessionsCompanion(
        currentExerciseIndex: Value(prevIndex),
      ));
    }
  }

  /// Pause session
  Future<void> pauseSession() async {
    await updateSessionCompanion(const ActiveSessionsCompanion(
      isActive: Value(false),
    ));
  }

  /// Resume session
  Future<void> resumeSession() async {
    await updateSessionCompanion(const ActiveSessionsCompanion(
      isActive: Value(true),
    ));
  }

  // ========== Clear/End Session ==========
  /// Clear the active session (end workout)
  Future<void> clearSession() async {
    await (delete(activeSessions)..where((t) => t.id.equals(1))).go();
  }

  /// End session and mark as inactive (without deleting)
  Future<void> endSession() async {
    await updateSessionCompanion(const ActiveSessionsCompanion(
      isActive: Value(false),
    ));
  }
}
