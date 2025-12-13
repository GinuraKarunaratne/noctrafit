import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'exercises_dao.g.dart';

@DriftAccessor(tables: [Exercises])
class ExercisesDao extends DatabaseAccessor<AppDatabase>
    with _$ExercisesDaoMixin {
  ExercisesDao(super.db);

  // Create
  Future<int> insertExercise(ExercisesCompanion exercise) {
    return into(exercises).insert(exercise);
  }

  Future<void> insertMultipleExercises(List<ExercisesCompanion> exerciseList) async {
    await batch((batch) {
      batch.insertAll(exercises, exerciseList);
    });
  }

  // Read
  Future<List<Exercise>> getAllExercises() {
    return select(exercises).get();
  }

  Future<Exercise?> getExerciseByUuid(String uuid) {
    return (select(exercises)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
  }

  Future<List<Exercise>> getExercisesByMuscleGroup(String muscleGroup) {
    return (select(exercises)
          ..where((t) => t.muscleGroup.equals(muscleGroup))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<Exercise>> getExercisesByEquipment(String equipment) {
    return (select(exercises)
          ..where((t) => t.equipment.equals(equipment))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<Exercise>> searchExercises(String query) {
    final lowercaseQuery = query.toLowerCase();
    return (select(exercises)
          ..where((t) => t.name.lower().contains(lowercaseQuery))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  // Update
  Future<bool> updateExercise(Exercise exercise) {
    return update(exercises).replace(exercise);
  }

  // Delete
  Future<int> deleteExercise(int id) {
    return (delete(exercises)..where((t) => t.id.equals(id))).go();
  }

  // Count
  Future<int> countExercises() async {
    final count = exercises.id.count();
    final query = selectOnly(exercises)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
