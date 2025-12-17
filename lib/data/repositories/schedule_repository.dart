import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/notification_service.dart';
import '../local/db/app_database.dart';
import '../local/db/daos/schedule_dao.dart';
import '../remote/firestore/user_remote_datasource.dart';

/// Repository for schedule entries
class ScheduleRepository {
  final ScheduleDao _dao;
  final UserRemoteDataSource? _userRemote;
  final FirebaseAuth? _auth;

  ScheduleRepository(
    this._dao, {
    UserRemoteDataSource? userRemote,
    FirebaseAuth? auth,
  })  : _userRemote = userRemote,
        _auth = auth;

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
    String? workoutName,
  }) async {
    final now = DateTime.now();
    final entryUuid = DateTime.now().millisecondsSinceEpoch.toString();

    final id = await _dao.insertEntry(ScheduleEntriesCompanion(
      uuid: Value(entryUuid),
      workoutSetId: Value(workoutSetId),
      scheduledDate: Value(scheduledDate),
      timeOfDay: Value(timeOfDay),
      note: Value(note),
      isCompleted: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    // Sync to Firestore if user is logged in
    final user = _auth?.currentUser;
    if (user != null && _userRemote != null) {
      try {
        await _userRemote.syncScheduleEntry(
          userId: user.uid,
          entryUuid: entryUuid,
          data: {
            'workout_set_id': workoutSetId,
            'scheduled_date': scheduledDate.toIso8601String(),
            'time_of_day': timeOfDay,
            'note': note,
            'is_completed': false,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
        );
      } catch (e) {
        // Log error but don't fail the schedule creation
      }
    }

    // Schedule notifications for this workout
    try {
      await NotificationService.scheduleWorkoutReminders(
        scheduleEntryId: id,
        workoutName: workoutName ?? 'Your Workout',
        scheduledDateTime: scheduledDate,
      );
    } catch (e) {
      // Log but don't fail - notifications are optional
      print('Failed to schedule notifications: $e');
    }

    return id;
  }

  // Update
  Future<bool> updateEntry(ScheduleEntry entry) => _dao.updateEntry(entry);
  Future<void> markAsCompleted(int id) => _dao.markAsCompleted(id);

  // Delete
  Future<int> deleteEntry(int id) async {
    // Get the entry to retrieve its UUID before deleting
    final allEntries = await _dao.getAllEntries();
    final entry = allEntries.firstWhere((e) => e.id == id, orElse: () => throw Exception('Entry not found'));

    final result = await _dao.deleteEntry(id);

    // Sync deletion to Firestore if user is logged in
    final user = _auth?.currentUser;
    if (user != null && _userRemote != null) {
      try {
        await _userRemote.deleteScheduleEntry(user.uid, entry.uuid);
      } catch (e) {
        // Log error but don't fail the deletion
      }
    }

    return result;
  }
  Future<void> deleteEntriesBeforeDate(DateTime date) =>
      _dao.deleteEntriesBeforeDate(date);

  // Count
  Future<int> countEntries() => _dao.countEntries();
}
