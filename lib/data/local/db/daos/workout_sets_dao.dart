import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'workout_sets_dao.g.dart';

@DriftAccessor(tables: [WorkoutSets])
class WorkoutSetsDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutSetsDaoMixin {
  WorkoutSetsDao(super.db);

  // ========== Create ==========
  Future<int> insertSet(WorkoutSetsCompanion set) {
    return into(workoutSets).insert(set);
  }

  Future<void> insertMultipleSets(List<WorkoutSetsCompanion> sets) async {
    await batch((batch) {
      batch.insertAll(workoutSets, sets);
    });
  }

  // ========== Read ==========
  /// Get all workout sets
  Future<List<WorkoutSet>> getAllSets() {
    return select(workoutSets).get();
  }

  /// Watch all workout sets (stream)
  Stream<List<WorkoutSet>> watchAllSets() {
    return (select(workoutSets)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  /// Get workout set by ID
  Future<WorkoutSet?> getSetById(int id) {
    return (select(workoutSets)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get workout set by UUID
  Future<WorkoutSet?> getSetByUuid(String uuid) {
    return (select(workoutSets)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
  }

  /// Get sets by source (seed, user, community)
  Future<List<WorkoutSet>> getSetsBySource(String source) {
    return (select(workoutSets)
          ..where((t) => t.source.equals(source))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Watch sets by source (stream)
  Stream<List<WorkoutSet>> watchSetsBySource(String source) {
    return (select(workoutSets)
          ..where((t) => t.source.equals(source))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Get favorite sets
  Future<List<WorkoutSet>> getFavoriteSets() {
    return (select(workoutSets)
          ..where((t) => t.isFavorite.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  /// Search sets by name or description
  Future<List<WorkoutSet>> searchSets(String query) {
    final lowercaseQuery = query.toLowerCase();
    return (select(workoutSets)
          ..where((t) =>
              t.name.lower().contains(lowercaseQuery) |
              t.description.lower().contains(lowercaseQuery))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Get sets by filters (category, difficulty, etc.)
  Future<List<WorkoutSet>> getSetsByFilter({
    String? source,
    String? category,
    String? difficulty,
    bool? isFavorite,
  }) {
    final query = select(workoutSets);

    if (source != null) {
      query.where((t) => t.source.equals(source));
    }
    if (category != null) {
      query.where((t) => t.category.equals(category));
    }
    if (difficulty != null) {
      query.where((t) => t.difficulty.equals(difficulty));
    }
    if (isFavorite != null) {
      query.where((t) => t.isFavorite.equals(isFavorite));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    return query.get();
  }

  /// Get sets sorted by criteria
  Future<List<WorkoutSet>> getSetsSorted({
    required String sortBy, // 'recent', 'name', 'duration', 'difficulty'
    bool ascending = false,
  }) {
    final query = select(workoutSets);

    switch (sortBy) {
      case 'recent':
        query.orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: ascending ? OrderingMode.asc : OrderingMode.desc)]);
        break;
      case 'name':
        query.orderBy([(t) => OrderingTerm(expression: t.name, mode: ascending ? OrderingMode.asc : OrderingMode.desc)]);
        break;
      case 'duration':
        query.orderBy([(t) => OrderingTerm(expression: t.estimatedMinutes, mode: ascending ? OrderingMode.asc : OrderingMode.desc)]);
        break;
      case 'difficulty':
        query.orderBy([(t) => OrderingTerm(expression: t.difficulty, mode: ascending ? OrderingMode.asc : OrderingMode.desc)]);
        break;
      default:
        query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    }

    return query.get();
  }

  // ========== Update ==========
  Future<bool> updateSet(WorkoutSet set) {
    return update(workoutSets).replace(set);
  }

  Future<void> updateSetCompanion(int id, WorkoutSetsCompanion companion) {
    return (update(workoutSets)..where((t) => t.id.equals(id))).write(companion);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(int id, bool isFavorite) {
    return (update(workoutSets)..where((t) => t.id.equals(id)))
        .write(WorkoutSetsCompanion(
      isFavorite: Value(isFavorite),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Update sync timestamp
  Future<void> updateSyncTimestamp(String uuid, DateTime timestamp) {
    return (update(workoutSets)..where((t) => t.uuid.equals(uuid)))
        .write(WorkoutSetsCompanion(
      lastSyncedAt: Value(timestamp),
    ));
  }

  // ========== Delete ==========
  Future<int> deleteSet(int id) {
    return (delete(workoutSets)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteSetByUuid(String uuid) {
    return (delete(workoutSets)..where((t) => t.uuid.equals(uuid))).go();
  }

  Future<void> deleteAllSets() {
    return delete(workoutSets).go();
  }

  // ========== Upsert (Insert or Update) ==========
  /// Insert or update a workout set based on UUID
  Future<void> upsertSet(WorkoutSet set) async {
    final existing = await getSetByUuid(set.uuid);
    if (existing == null) {
      await insertSet(set.toCompanion(false));
    } else {
      await updateSet(set);
    }
  }

  // ========== Count ==========
  Future<int> countSets() async {
    final count = workoutSets.id.count();
    final query = selectOnly(workoutSets)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> countSetsBySource(String source) async {
    final count = workoutSets.id.count();
    final query = selectOnly(workoutSets)
      ..addColumns([count])
      ..where(workoutSets.source.equals(source));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
