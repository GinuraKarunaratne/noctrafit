import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'schedule_dao.g.dart';

@DriftAccessor(tables: [ScheduleEntries])
class ScheduleDao extends DatabaseAccessor<AppDatabase>
    with _$ScheduleDaoMixin {
  ScheduleDao(super.db);

  // Create
  Future<int> insertEntry(ScheduleEntriesCompanion entry) {
    return into(scheduleEntries).insert(entry);
  }

  // Read
  Future<List<ScheduleEntry>> getAllEntries() {
    return select(scheduleEntries).get();
  }

  Stream<List<ScheduleEntry>> watchAllEntries() {
    return (select(scheduleEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .watch();
  }

  Future<ScheduleEntry?> getEntryByUuid(String uuid) {
    return (select(scheduleEntries)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
  }

  /// Get entries for a specific date
  Future<List<ScheduleEntry>> getEntriesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(scheduleEntries)
          ..where((t) =>
              t.scheduledDate.isBiggerOrEqualValue(startOfDay) &
              t.scheduledDate.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .get();
  }

  /// Get entries for a date range
  Future<List<ScheduleEntry>> getEntriesInRange(DateTime start, DateTime end) {
    return (select(scheduleEntries)
          ..where((t) =>
              t.scheduledDate.isBiggerOrEqualValue(start) &
              t.scheduledDate.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .get();
  }

  /// Get upcoming entries
  Future<List<ScheduleEntry>> getUpcomingEntries({int limit = 10}) {
    final now = DateTime.now();
    return (select(scheduleEntries)
          ..where((t) => t.scheduledDate.isBiggerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)])
          ..limit(limit))
        .get();
  }

  /// Get incomplete entries
  Future<List<ScheduleEntry>> getIncompleteEntries() {
    return (select(scheduleEntries)
          ..where((t) => t.isCompleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .get();
  }

  // Update
  Future<bool> updateEntry(ScheduleEntry entry) {
    return update(scheduleEntries).replace(entry);
  }

  Future<void> markAsCompleted(int id) {
    return (update(scheduleEntries)..where((t) => t.id.equals(id)))
        .write(ScheduleEntriesCompanion(
      isCompleted: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Delete
  Future<int> deleteEntry(int id) {
    return (delete(scheduleEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteEntriesBeforeDate(DateTime date) {
    return (delete(scheduleEntries)..where((t) => t.scheduledDate.isSmallerThanValue(date))).go();
  }

  // Count
  Future<int> countEntries() async {
    final count = scheduleEntries.id.count();
    final query = selectOnly(scheduleEntries)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
