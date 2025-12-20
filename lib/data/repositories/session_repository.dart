import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../local/db/app_database.dart';
import '../local/db/daos/active_session_dao.dart';
import '../local/db/daos/completion_logs_dao.dart';
import '../local/db/daos/workout_sets_dao.dart';
import '../remote/firestore/sets_remote_datasource.dart';
import '../remote/firestore/user_remote_datasource.dart';

/// Repository for active workout session management
class SessionRepository {
  final ActiveSessionDao _sessionDao;
  final CompletionLogsDao _logsDao;
  final WorkoutSetsDao? _workoutSetsDao;
  final SetsRemoteDataSource? _setsRemote;
  final UserRemoteDataSource? _userRemote;
  final FirebaseAuth? _auth;

  SessionRepository(
    this._sessionDao,
    this._logsDao, {
    UserRemoteDataSource? userRemote,
    FirebaseAuth? auth,
    WorkoutSetsDao? workoutSetsDao,
    SetsRemoteDataSource? setsRemote,
  })  : _userRemote = userRemote,
        _auth = auth,
        _workoutSetsDao = workoutSetsDao,
        _setsRemote = setsRemote;

  // ========== Read ==========
  Future<ActiveSession?> getActiveSession() => _sessionDao.getActiveSession();
  Stream<ActiveSession?> watchActiveSession() => _sessionDao.watchActiveSession();
  Future<bool> hasActiveSession() => _sessionDao.hasActiveSession();

  /// ✅ NEW: validate route session uuid
  Future<ActiveSession?> getSessionByUuid(String sessionUuid) =>
      _sessionDao.getSessionByUuid(sessionUuid);

  Stream<ActiveSession?> watchSessionByUuid(String sessionUuid) =>
      _sessionDao.watchSessionByUuid(sessionUuid);

  // ========== Create/Start ==========
  /// ✅ NOW RETURNS sessionUuid (important for correct navigation)
  Future<String> startSession({
    required int workoutSetId,
    required String workoutSetName,
    required int totalExercises,
    required int estimatedMinutes,
    String? workoutSetUuid,
  }) async {
    final now = DateTime.now();
    final sessionUuid = now.millisecondsSinceEpoch.toString();

    await _sessionDao.startSession(ActiveSessionsCompanion(
      id: const Value(1),
      sessionUuid: Value(sessionUuid),
      workoutSetId: Value(workoutSetId),
      workoutSetUuid: Value(workoutSetUuid),
      workoutSetName: Value(workoutSetName),
      startedAt: Value(now),
      currentExerciseIndex: const Value(0),
      totalExercises: Value(totalExercises),
      estimatedMinutes: Value(estimatedMinutes),
      completedExercises: const Value('[]'),
      isActive: const Value(true),
      lastUpdatedAt: Value(now),
    ));

    return sessionUuid;
  }

  // ========== Update ==========
  Future<void> updateSession(ActiveSession session) => _sessionDao.updateSession(session);

  Future<void> progressToNextExercise() => _sessionDao.progressToNextExercise();
  Future<void> goToPreviousExercise() => _sessionDao.goToPreviousExercise();

  Future<void> pauseSession() => _sessionDao.pauseSession();
  Future<void> resumeSession() => _sessionDao.resumeSession();

  Future<void> markExerciseCompleted(
    int exerciseIndex,
    Map<String, dynamic> exerciseData,
  ) async {
    final session = await _sessionDao.getActiveSession();
    if (session == null) return;

    final List<dynamic> completed = jsonDecode(session.completedExercises);

    completed.add({
      'index': exerciseIndex,
      'data': exerciseData,
      'completed_at': DateTime.now().toIso8601String(),
    });

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
    final logUuid = now.millisecondsSinceEpoch.toString();

    // Create completion log locally
    await _logsDao.insertLog(CompletionLogsCompanion(
      uuid: Value(logUuid),
      workoutSetId: Value(session.workoutSetId),
      scheduleEntryId: const Value(null),
      startedAt: Value(session.startedAt),
      completedAt: Value(now),
      durationSeconds: Value(duration.inSeconds),
      exercisesCompleted: Value(session.completedExercises),
      notes: const Value(null),
      createdAt: Value(now),
    ));

    // Sync to Firestore if user logged in
    final user = _auth?.currentUser;
    if (user != null && _userRemote != null) {
      try {
        final Map<String, dynamic> payload = {
          'workout_set_id': session.workoutSetId,
          'workout_set_uuid': session.workoutSetUuid,
          'workout_set_name': session.workoutSetName,
          'session_uuid': session.sessionUuid,
          'started_at': session.startedAt.toIso8601String(),
          'completed_at': now.toIso8601String(),
          'duration_seconds': duration.inSeconds,
          'created_at': now.toIso8601String(),
        };

        // Build per-exercise completion list + completion_percentage
        try {
          final rawCompleted = jsonDecode(session.completedExercises) as List<dynamic>;

          final Map<int, Map<String, dynamic>> completedByIndex = {};
          for (final c in rawCompleted) {
            try {
              final map = Map<String, dynamic>.from(c as Map);
              final idx = map['index'];
              if (idx is int) completedByIndex[idx] = map;
            } catch (_) {}
          }

          final int total = session.totalExercises;
          final List<Map<String, dynamic>> exercisesList =
              List.generate(total, (i) {
            final base = <String, dynamic>{'index': i};
            if (completedByIndex.containsKey(i)) {
              base.addAll(completedByIndex[i]!);
              base['done'] = true;
            } else {
              base['done'] = false;
            }
            return base;
          });

          payload['exercises_completed'] = exercisesList;

          final doneCount = exercisesList.where((e) => e['done'] == true).length;
          final percent = total > 0 ? (doneCount / total) * 100.0 : 0.0;
          payload['completion_percentage'] = percent.round();
        } catch (_) {
          payload['exercises_completed'] = session.completedExercises;
        }

        // Prefer remote set by uuid
        final String? setUuid = session.workoutSetUuid;
        if (setUuid != null && setUuid.trim().isNotEmpty && _setsRemote != null) {
          try {
            final remoteSet =
                await _setsRemote.fetchCommunitySetByUuid(uuid: setUuid);
            if (remoteSet != null) payload['workout_set'] = remoteSet;
          } catch (_) {}
        }

        // Fallback: attach local workout set details
        if (!payload.containsKey('workout_set')) {
          try {
            final set = _workoutSetsDao == null
                ? null
                : await _workoutSetsDao.getSetById(session.workoutSetId);

            if (set != null) {
              dynamic exercisesValue;
              try {
                exercisesValue = jsonDecode(set.exercises);
              } catch (_) {
                exercisesValue = set.exercises;
              }

              payload['workout_set'] = {
                'uuid': set.uuid,
                'name': set.name,
                'description': set.description,
                'difficulty': set.difficulty,
                'category': set.category,
                'estimated_minutes': set.estimatedMinutes,
                'exercises': exercisesValue,
                'source': set.source,
                'author_id': set.authorId,
                'author_name': set.authorName,
                'created_at': set.createdAt.toIso8601String(),
                'updated_at': set.updatedAt.toIso8601String(),
              };
            }
          } catch (_) {}
        }

        await _userRemote.syncCompletionLog(
          userId: user.uid,
          logUuid: logUuid,
          data: payload,
        );
      } catch (_) {
        // keep local log; sync can retry later
      }
    }

    // Clear active session
    await _sessionDao.clearSession();
  }

  Future<void> cancelSession() => _sessionDao.clearSession();

  // ========== Utility ==========
  int calculateElapsedSeconds(ActiveSession session) =>
      DateTime.now().difference(session.startedAt).inSeconds;

  double calculateProgress(ActiveSession session) {
    if (session.totalExercises == 0) return 0.0;
    return session.currentExerciseIndex / session.totalExercises;
  }
}
