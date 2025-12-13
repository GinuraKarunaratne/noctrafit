import 'package:drift/drift.dart';
import '../local/db/app_database.dart';
import '../local/db/daos/schedule_dao.dart';

/// Repository for schedule entries
class ScheduleRepository {
  final ScheduleDao _dao;

  ScheduleRepository(this._dao);

  // Read
  Future<List<ScheduleEntry>> getAllEntries() => _dao.getAllEntries();
  Stream<List<ScheduleEntry>> watchAllEntries() => _dao.watchAllEntries();

  Future<ScheduleEntry?> getEntryByUuid(String uuid) => _dao.getEntryByUuid(uuid);

  Future<List<ScheduleEntry>> getEntriesForDate(DateTime date) =>
      _dao.getEntriesForDate(date);

  Future<List<ScheduleEntry>> getEntriesInRange(DateTime start, DateTime end) =>
      _dao.getEntriesInRange(start, end);

  Future<List<ScheduleEntry>> getUpcomingEntries({int limit = 10}) =>
      _dao.getUpcomingEntries(limit: limit);

  Future<List<ScheduleEntry>> getIncompleteEntries() =>
      _dao.getIncompleteEntries();

  // Create
  Future<int> scheduleWorkout({
    required int workoutSetId,
    required DateTime scheduledDate,
    required String timeOfDay,
    String? note,
  }) {
    final now = DateTime.now();
    return _dao.insertEntry(ScheduleEntriesCompanion(
      uuid: Value(DateTime.now().millisecondsSinceEpoch.toString()),
      workoutSetId: Value(workoutSetId),
      scheduledDate: Value(scheduledDate),
      timeOfDay: Value(timeOfDay),
      note: Value(note),
      isCompleted: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  // Update
  Future<bool> updateEntry(ScheduleEntry entry) => _dao.updateEntry(entry);
  Future<void> markAsCompleted(int id) => _dao.markAsCompleted(id);

  // Delete
  Future<int> deleteEntry(int id) => _dao.deleteEntry(id);
  Future<void> deleteEntriesBeforeDate(DateTime date) =>
      _dao.deleteEntriesBeforeDate(date);

  // Count
  Future<int> countEntries() => _dao.countEntries();
}
