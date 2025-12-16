import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';
import 'daos/workout_sets_dao.dart';
import 'daos/exercises_dao.dart';
import 'daos/schedule_dao.dart';
import 'daos/completion_logs_dao.dart';
import 'daos/preferences_dao.dart';
import 'daos/active_session_dao.dart';
import 'daos/sync_queue_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    WorkoutSets,
    Exercises,
    ScheduleEntries,
    CompletionLogs,
    Preferences,
    ActiveSessions,
    SyncQueue,
  ],
  daos: [
    WorkoutSetsDao,
    ExercisesDao,
    ScheduleDao,
    CompletionLogsDao,
    PreferencesDao,
    ActiveSessionDao,
    SyncQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // Create all tables
        await m.createAll();

        // Create indexes for performance
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_workout_sets_source ON workout_sets(source);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_workout_sets_category ON workout_sets(category);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_workout_sets_difficulty ON workout_sets(difficulty);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_schedule_entries_date ON schedule_entries(scheduled_date);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_completion_logs_date ON completion_logs(completed_at);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_completion_logs_workout ON completion_logs(workout_set_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sync_queue_entity ON sync_queue(entity_type, entity_uuid);',
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migration path from version 1 -> 2: add `workout_set_uuid` to active_sessions
        if (from < 2) {
          try {
            await customStatement(
              'ALTER TABLE active_sessions ADD COLUMN workout_set_uuid TEXT;'
            );
          } catch (_) {
            // If ALTER fails (e.g., column already exists), ignore and continue
          }
        }
      },
    );
  }

  // Close database connection
  Future<void> closeDb() async {
    await close();
  }
}

/// Opens a connection to the SQLite database
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'noctrafit.db'));
    return NativeDatabase.createInBackground(file);
  });
}
