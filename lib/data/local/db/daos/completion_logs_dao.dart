import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'completion_logs_dao.g.dart';

@DriftAccessor(tables: [CompletionLogs])
class CompletionLogsDao extends DatabaseAccessor<AppDatabase>
    with _$CompletionLogsDaoMixin {
  CompletionLogsDao(super.db);

  // Create
  Future<int> insertLog(CompletionLogsCompanion log) {
    return into(completionLogs).insert(log);
  }

  // Read
  Future<List<CompletionLog>> getAllLogs() {
    return (select(completionLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  Stream<List<CompletionLog>> watchAllLogs() {
    return (select(completionLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .watch();
  }

  Future<CompletionLog?> getLogByUuid(String uuid) {
    return (select(completionLogs)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
  }

  /// Get logs for a specific workout set
  Future<List<CompletionLog>> getLogsForWorkoutSet(int workoutSetId) {
    return (select(completionLogs)
          ..where((t) => t.workoutSetId.equals(workoutSetId))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  /// Get logs for a date range (for insights)
  Future<List<CompletionLog>> getLogsInRange(DateTime start, DateTime end) {
    return (select(completionLogs)
          ..where((t) =>
              t.completedAt.isBiggerOrEqualValue(start) &
              t.completedAt.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  /// Get logs for the last N days
  Future<List<CompletionLog>> getRecentLogs(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return (select(completionLogs)
          ..where((t) => t.completedAt.isBiggerOrEqualValue(cutoffDate))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  /// Get logs for the current year (for heatmap)
  Future<List<CompletionLog>> getLogsForYear([int? year]) {
    final targetYear = year ?? DateTime.now().year;
    final startOfYear = DateTime(targetYear, 1, 1);
    final endOfYear = DateTime(targetYear + 1, 1, 1);
    return getLogsInRange(startOfYear, endOfYear);
  }

  /// Get completion count by date (for heatmap)
  Future<Map<DateTime, int>> getCompletionCountByDate(DateTime start, DateTime end) async {
    final logs = await getLogsInRange(start, end);
    final Map<DateTime, int> countByDate = {};

    for (final log in logs) {
      final dateOnly = DateTime(
        log.completedAt.year,
        log.completedAt.month,
        log.completedAt.day,
      );
      countByDate[dateOnly] = (countByDate[dateOnly] ?? 0) + 1;
    }

    return countByDate;
  }

  // Update
  Future<bool> updateLog(CompletionLog log) {
    return update(completionLogs).replace(log);
  }

  // Delete
  Future<int> deleteLog(int id) {
    return (delete(completionLogs)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteLogsBeforeDate(DateTime date) {
    return (delete(completionLogs)..where((t) => t.completedAt.isSmallerThanValue(date))).go();
  }

  // Count & Stats
  Future<int> countLogs() async {
    final count = completionLogs.id.count();
    final query = selectOnly(completionLogs)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> countLogsInRange(DateTime start, DateTime end) async {
    final count = completionLogs.id.count();
    final query = selectOnly(completionLogs)
      ..addColumns([count])
      ..where(completionLogs.completedAt.isBiggerOrEqualValue(start) &
          completionLogs.completedAt.isSmallerOrEqualValue(end));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> getTotalMinutesInRange(DateTime start, DateTime end) async {
    final sum = completionLogs.durationSeconds.sum();
    final query = selectOnly(completionLogs)
      ..addColumns([sum])
      ..where(completionLogs.completedAt.isBiggerOrEqualValue(start) &
          completionLogs.completedAt.isSmallerOrEqualValue(end));
    final result = await query.getSingle();
    final totalSeconds = result.read(sum) ?? 0;
    return (totalSeconds / 60).round();
  }
}
