import '../local/db/app_database.dart';
import '../local/db/daos/completion_logs_dao.dart';

/// Repository for insights and statistics
class InsightsRepository {
  final CompletionLogsDao _dao;

  InsightsRepository(this._dao);

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

  Future<int> getWorkoutsThisWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return _dao.countLogsInRange(startOfWeek, endOfWeek);
  }

  Future<int> getWorkoutsThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    return _dao.countLogsInRange(startOfMonth, endOfMonth);
  }

  Future<int> getTotalMinutesThisWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return _dao.getTotalMinutesInRange(startOfWeek, endOfWeek);
  }

  Future<int> getTotalMinutesThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    return _dao.getTotalMinutesInRange(startOfMonth, endOfMonth);
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

  // Delete
  Future<int> deleteLog(int id) => _dao.deleteLog(id);
  Future<void> deleteLogsBeforeDate(DateTime date) =>
      _dao.deleteLogsBeforeDate(date);
}
