import '../local/db/app_database.dart';
import '../local/db/daos/completion_logs_dao.dart';
import '../remote/firestore/user_remote_datasource.dart';

/// Repository for insights and statistics
class InsightsRepository {
  final CompletionLogsDao _dao;
  final UserRemoteDataSource? _remote;

  InsightsRepository(this._dao, {UserRemoteDataSource? remote}) : _remote = remote;

  // Read logs
  Future<List<CompletionLog>> getAllLogs() => _dao.getAllLogs();
  Stream<List<CompletionLog>> watchAllLogs() => _dao.watchAllLogs();

  Future<List<CompletionLog>> getLogsForWorkoutSet(int workoutSetId) =>
      _dao.getLogsForWorkoutSet(workoutSetId);

  Future<List<CompletionLog>> getLogsInRange(DateTime start, DateTime end) =>
      _dao.getLogsInRange(start, end);

  Future<List<CompletionLog>> getRecentLogs(int days) =>
      _dao.getRecentLogs(days);

  Future<List<CompletionLog>> getLogsForYear([int? year]) =>
      _dao.getLogsForYear(year);

  // Stats for heatmap
  Future<Map<DateTime, int>> getCompletionHeatmapData(DateTime start, DateTime end) =>
      _dao.getCompletionCountByDate(start, end);

  Future<Map<DateTime, int>> getYearHeatmap([int? year]) async {
    final targetYear = year ?? DateTime.now().year;
    final start = DateTime(targetYear, 1, 1);
    final end = DateTime(targetYear + 1, 1, 1);
    return _dao.getCompletionCountByDate(start, end);
  }

  // Aggregated stats
  Future<int> getTotalWorkouts() => _dao.countLogs();

  Future<int> getTotalWorkoutsRemote(String userId) async {
    if (_remote == null) return getTotalWorkouts();
    final docs = await _remote.fetchCompletionLogs(userId: userId);
    return docs.length;
  }

  Future<int> getWorkoutsThisWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return _dao.countLogsInRange(startOfWeek, endOfWeek);
  }

  /// Remote versions (use Firestore data when available)
  Future<int> getWorkoutsThisWeekRemote(String userId) async {
    if (_remote == null) return getWorkoutsThisWeek();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final docs = await _remote.fetchCompletionLogs(userId: userId, start: startOfWeek, end: endOfWeek);
    return docs.length;
  }

  Future<int> getWorkoutsThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    return _dao.countLogsInRange(startOfMonth, endOfMonth);
  }

  Future<int> getWorkoutsThisMonthRemote(String userId) async {
    if (_remote == null) return getWorkoutsThisMonth();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    final docs = await _remote.fetchCompletionLogs(userId: userId, start: startOfMonth, end: endOfMonth);
    return docs.length;
  }

  Future<int> getTotalMinutesThisWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return _dao.getTotalMinutesInRange(startOfWeek, endOfWeek);
  }

  Future<int> getTotalMinutesThisWeekRemote(String userId) async {
    if (_remote == null) return getTotalMinutesThisWeek();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final docs = await _remote.fetchCompletionLogs(userId: userId, start: startOfWeek, end: endOfWeek);
    int totalSeconds = 0;
    for (final d in docs) {
      final ds = d['duration_seconds'];
      if (ds is int) {
        totalSeconds += ds;
      } else if (ds is String) totalSeconds += int.tryParse(ds) ?? 0;
    }
    return (totalSeconds / 60).round();
  }

  Future<int> getTotalMinutesThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    return _dao.getTotalMinutesInRange(startOfMonth, endOfMonth);
  }

  Future<int> getTotalMinutesThisMonthRemote(String userId) async {
    if (_remote == null) return getTotalMinutesThisMonth();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    final docs = await _remote.fetchCompletionLogs(userId: userId, start: startOfMonth, end: endOfMonth);
    int totalSeconds = 0;
    for (final d in docs) {
      final ds = d['duration_seconds'];
      if (ds is int) {
        totalSeconds += ds;
      } else if (ds is String) totalSeconds += int.tryParse(ds) ?? 0;
    }
    return (totalSeconds / 60).round();
  }

  /// Remote logs in range
  Future<List<Map<String, dynamic>>> getLogsInRangeRemote(String userId, DateTime start, DateTime end) async {
    if (_remote == null) {
      final local = await getLogsInRange(start, end);
      return local.map((l) => {
        'uuid': l.uuid,
        'workout_set_id': l.workoutSetId,
        'completed_at': l.completedAt.toIso8601String(),
        'duration_seconds': l.durationSeconds,
        'exercises_completed': l.exercisesCompleted,
      }).toList();
    }

    final docs = await _remote.fetchCompletionLogs(userId: userId, start: start, end: end);
    return docs.cast<Map<String, dynamic>>();
  }

  // Streak calculation
  Future<int> getCurrentStreak() async {
    final logs = await _dao.getRecentLogs(365);
    if (logs.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Group logs by date
    final logsByDate = <DateTime, List<CompletionLog>>{};
    for (final log in logs) {
      final date = DateTime(
        log.completedAt.year,
        log.completedAt.month,
        log.completedAt.day,
      );
      logsByDate.putIfAbsent(date, () => []).add(log);
    }

    // Calculate streak
    int streak = 0;
    var checkDate = todayDate;

    while (logsByDate.containsKey(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<int> getCurrentStreakRemote(String userId) async {
    if (_remote == null) return getCurrentStreak();
    final docs = await _remote.fetchCompletionLogs(userId: userId);
    if (docs.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final logsByDate = <DateTime, List<Map<String, dynamic>>>{};
    for (final d in docs) {
      final completedAtRaw = d['completed_at'];
      if (completedAtRaw == null) continue;
      try {
        final dt = DateTime.parse(completedAtRaw.toString());
        final dateOnly = DateTime(dt.year, dt.month, dt.day);
        logsByDate.putIfAbsent(dateOnly, () => []).add(d);
      } catch (_) {
        continue;
      }
    }

    int streak = 0;
    var checkDate = todayDate;
    while (logsByDate.containsKey(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // Delete
  Future<int> deleteLog(int id) => _dao.deleteLog(id);
  Future<void> deleteLogsBeforeDate(DateTime date) =>
      _dao.deleteLogsBeforeDate(date);
}
