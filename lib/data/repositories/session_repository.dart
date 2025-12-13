import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../local/db/app_database.dart';
import '../local/db/daos/active_session_dao.dart';
import '../local/db/daos/completion_logs_dao.dart';
import '../remote/firestore/user_remote_datasource.dart';

/// Repository for active workout session management
class SessionRepository {
  final ActiveSessionDao _sessionDao;
  final CompletionLogsDao _logsDao;
  final UserRemoteDataSource? _userRemote;
  final FirebaseAuth? _auth;

  SessionRepository(
    this._sessionDao,
    this._logsDao, {
    UserRemoteDataSource? userRemote,
    FirebaseAuth? auth,
  })  : _userRemote = userRemote,
        _auth = auth;

  // ========== Read ==========
  Future<ActiveSession?> getActiveSession() => _sessionDao.getActiveSession();
  Stream<ActiveSession?> watchActiveSession() => _sessionDao.watchActiveSession();
  Future<bool> hasActiveSession() => _sessionDao.hasActiveSession();

  // ========== Create/Start ==========
  Future<void> startSession({
    required int workoutSetId,
    required String workoutSetName,
    required int totalExercises,
    required int estimatedMinutes,
  }) async {
    final now = DateTime.now();
    final sessionUuid = now.millisecondsSinceEpoch.toString();

    await _sessionDao.startSession(ActiveSessionsCompanion(
      id: const Value(1), // Always 1 (single row table)
      sessionUuid: Value(sessionUuid),
      workoutSetId: Value(workoutSetId),
      workoutSetName: Value(workoutSetName),
      startedAt: Value(now),
      currentExerciseIndex: const Value(0),
      totalExercises: Value(totalExercises),
      estimatedMinutes: Value(estimatedMinutes),
      completedExercises: const Value('[]'), // Empty JSON array
      isActive: const Value(true),
      lastUpdatedAt: Value(now),
    ));
  }

  // ========== Update ==========
  Future<void> updateSession(ActiveSession session) =>
      _sessionDao.updateSession(session);

  Future<void> progressToNextExercise() =>
      _sessionDao.progressToNextExercise();

  Future<void> goToPreviousExercise() =>
      _sessionDao.goToPreviousExercise();

  Future<void> pauseSession() => _sessionDao.pauseSession();
  Future<void> resumeSession() => _sessionDao.resumeSession();

  Future<void> markExerciseCompleted(int exerciseIndex, Map<String, dynamic> exerciseData) async {
    final session = await _sessionDao.getActiveSession();
    if (session == null) return;

    // Parse completed exercises
    final List<dynamic> completed = jsonDecode(session.completedExercises);

    // Add new completion
    completed.add({
      'index': exerciseIndex,
      'data': exerciseData,
      'completed_at': DateTime.now().toIso8601String(),
    });

    // Update session
    await _sessionDao.updateSessionCompanion(ActiveSessionsCompanion(
      completedExercises: Value(jsonEncode(completed)),
    ));
  }

  // ========== Complete/End Session ==========
  Future<void> completeSession() async {
    final session = await _sessionDao.getActiveSession();
    if (session == null) return;

    final now = DateTime.now();
    final duration = now.difference(session.startedAt);
    final logUuid = DateTime.now().millisecondsSinceEpoch.toString();

    // Create completion log locally
    await _logsDao.insertLog(CompletionLogsCompanion(
      uuid: Value(logUuid),
      workoutSetId: Value(session.workoutSetId),
      scheduleEntryId: const Value(null), // TODO: Link if scheduled
      startedAt: Value(session.startedAt),
      completedAt: Value(now),
      durationSeconds: Value(duration.inSeconds),
      exercisesCompleted: Value(session.completedExercises),
      notes: const Value(null),
      createdAt: Value(now),
    ));

    // Sync to Firestore if user is logged in
    final user = _auth?.currentUser;
    if (user != null && _userRemote != null) {
      try {
        await _userRemote.syncCompletionLog(
          userId: user.uid,
          logUuid: logUuid,
          data: {
            'workout_set_id': session.workoutSetId,
            'workout_set_name': session.workoutSetName,
            'started_at': session.startedAt.toIso8601String(),
            'completed_at': now.toIso8601String(),
            'duration_seconds': duration.inSeconds,
            'exercises_completed': session.completedExercises,
            'created_at': now.toIso8601String(),
          },
        );
      } catch (e) {
        // Log error but don't fail the completion
        // The completion log is saved locally, sync can retry later
      }
    }

    // Clear active session
    await _sessionDao.clearSession();
  }

  Future<void> cancelSession() => _sessionDao.clearSession();

  // ========== Calculate elapsed time ==========
  int calculateElapsedSeconds(ActiveSession session) {
    return DateTime.now().difference(session.startedAt).inSeconds;
  }

  // ========== Progress percentage ==========
  double calculateProgress(ActiveSession session) {
    if (session.totalExercises == 0) return 0.0;
    return session.currentExerciseIndex / session.totalExercises;
  }
}
