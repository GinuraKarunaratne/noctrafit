import 'package:drift/drift.dart';

// ========== Table 1: workout_sets (Main Content Entity) ==========
/// Stores workout set templates (from seed, user-created, or community)
@DataClassName('WorkoutSet')
class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();

  /// beginner, intermediate, advanced
  TextColumn get difficulty => text()();

  /// strength, cardio, flexibility, hybrid
  TextColumn get category => text()();

  IntColumn get estimatedMinutes => integer()();

  /// JSON array of exercises: [{exercise_uuid, sets, reps, duration_sec, rest_sec}]
  TextColumn get exercises => text()();

  /// seed (from assets), user (created locally), community (from Firestore)
  TextColumn get source => text()();

  /// Firebase UID if community set
  TextColumn get authorId => text().nullable()();

  /// Display name if community set
  TextColumn get authorName => text().nullable()();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
}

// ========== Table 2: exercises (Reference Library) ==========
/// Pre-populated exercise reference library from seed data
@DataClassName('Exercise')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text()();

  /// chest, back, legs, core, cardio, arms, shoulders
  TextColumn get muscleGroup => text()();

  /// bodyweight, dumbbells, barbell, machine, resistance_band, kettlebell
  TextColumn get equipment => text()();

  /// Step-by-step instructions
  TextColumn get instructions => text().nullable()();

  /// Optional video URL
  TextColumn get videoUrl => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}

// ========== Table 3: schedule_entries (User's Schedule) ==========
/// Scheduled workouts in the user's calendar
@DataClassName('ScheduleEntry')
class ScheduleEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// Foreign key to workout_sets
  IntColumn get workoutSetId => integer().references(WorkoutSets, #id, onDelete: KeyAction.cascade)();

  /// Unix timestamp (date only, time set to 00:00)
  DateTimeColumn get scheduledDate => dateTime()();

  /// morning, afternoon, evening, night
  TextColumn get timeOfDay => text()();

  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Optional note from user
  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// ========== Table 4: completion_logs (Workout History) ==========
/// Records of completed workouts for insights and progress tracking
@DataClassName('CompletionLog')
class CompletionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// Foreign key to workout_sets (nullable if set was deleted)
  IntColumn get workoutSetId => integer().nullable().references(WorkoutSets, #id, onDelete: KeyAction.setNull)();

  /// Foreign key to schedule_entries (nullable if ad-hoc workout)
  IntColumn get scheduleEntryId => integer().nullable().references(ScheduleEntries, #id, onDelete: KeyAction.setNull)();

  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime()();

  /// Total duration in seconds
  IntColumn get durationSeconds => integer()();

  /// JSON array: [{exercise_uuid, sets: [{reps, weight_kg}]}]
  TextColumn get exercisesCompleted => text()();

  /// User notes about the workout
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}

// ========== Table 5: preferences (Key-Value Store) ==========
/// App preferences and flags (has_seeded, device_id, theme_mode, etc.)
@DataClassName('Preference')
class Preferences extends Table {
  /// Preference key
  TextColumn get key => text()();

  /// Preference value (stored as string, parse as needed)
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ========== Table 6: active_session (Single Row) ==========
/// Stores the currently active workout session (survives app restart)
/// IMPORTANT: Only ONE row allowed (id = 1)
@DataClassName('ActiveSession')
class ActiveSessions extends Table {
  /// Always 1 (enforced by constraint)
  IntColumn get id => integer().check(id.equals(1))();

  TextColumn get sessionUuid => text()();

  /// Foreign key to workout_sets
  IntColumn get workoutSetId => integer().references(WorkoutSets, #id, onDelete: KeyAction.cascade)();

  /// Workout set name (cached for display)
  TextColumn get workoutSetName => text()();

  /// When the session started
  DateTimeColumn get startedAt => dateTime()();

  /// Current exercise index (0-based)
  IntColumn get currentExerciseIndex => integer()();

  /// Total number of exercises in the set
  IntColumn get totalExercises => integer()();

  /// Estimated duration in minutes
  IntColumn get estimatedMinutes => integer()();

  /// JSON array of completed exercise indices
  TextColumn get completedExercises => text()();

  /// Whether session is active (false = paused or ended)
  BoolColumn get isActive => boolean()();

  /// Last update timestamp
  DateTimeColumn get lastUpdatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ========== Table 7: sync_queue (Firestore Sync Queue) ==========
/// Queue of pending operations to sync with Firestore
@DataClassName('SyncQueueItem')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Type of entity (workout_set, schedule_entry, completion_log)
  TextColumn get entityType => text()();

  /// UUID of the entity
  TextColumn get entityUuid => text()();

  /// Operation: create, update, delete
  TextColumn get operation => text()();

  /// JSON payload of the entity
  TextColumn get payload => text()();

  DateTimeColumn get createdAt => dateTime()();

  /// Number of retry attempts
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Last error message (if any)
  TextColumn get lastError => text().nullable()();
}
