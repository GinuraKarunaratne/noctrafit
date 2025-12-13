import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../db/app_database.dart';

/// Loads seed data from JSON into the database on first app launch
/// CRITICAL: Must run BEFORE the UI is displayed to ensure offline-first
class SeedLoader {
  final AppDatabase _db;
  final Logger _logger = Logger();

  SeedLoader(this._db);

  /// Load seed data if not already loaded
  /// Returns true if data was loaded, false if already seeded
  Future<bool> loadSeedDataIfNeeded() async {
    try {
      // Check if already seeded
      final hasSeeded = await _db.preferencesDao.hasSeeded();
      if (hasSeeded) {
        _logger.i('Seed data already loaded, skipping');
        return false;
      }

      _logger.i('Loading seed data for first time...');

      // Load JSON file
      final jsonString = await rootBundle.loadString('assets/seed/workouts_seed.json');
      final seedData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Load exercises first (reference library)
      await _loadExercises(seedData['exercises'] as List);

      // Load workout sets
      await _loadWorkoutSets(seedData['workout_sets'] as List);

      // Mark as seeded
      await _db.preferencesDao.setHasSeeded(true);

      // Generate and store device ID
      final deviceId = const Uuid().v4();
      await _db.preferencesDao.setDeviceId(deviceId);

      _logger.i('Seed data loaded successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to load seed data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Load exercises into the database
  Future<void> _loadExercises(List exercisesJson) async {
    final exercises = exercisesJson.map((e) {
      return ExercisesCompanion(
        uuid: Value(e['uuid'] as String),
        name: Value(e['name'] as String),
        muscleGroup: Value(e['muscle_group'] as String),
        equipment: Value(e['equipment'] as String),
        instructions: Value(e['instructions'] as String?),
        videoUrl: Value(e['video_url'] as String?),
        createdAt: Value(DateTime.now()),
      );
    }).toList();

    await _db.exercisesDao.insertMultipleExercises(exercises);
    _logger.i('Loaded ${exercises.length} exercises');
  }

  /// Load workout sets into the database
  Future<void> _loadWorkoutSets(List workoutSetsJson) async {
    final now = DateTime.now();

    final workoutSets = workoutSetsJson.map((ws) {
      // Convert exercises array to JSON string
      final exercisesJson = jsonEncode(ws['exercises']);

      return WorkoutSetsCompanion(
        uuid: Value(ws['uuid'] as String),
        name: Value(ws['name'] as String),
        description: Value(ws['description'] as String?),
        difficulty: Value(ws['difficulty'] as String),
        category: Value(ws['category'] as String),
        estimatedMinutes: Value(ws['estimated_minutes'] as int),
        exercises: Value(exercisesJson),
        source: Value(ws['source'] as String), // Should be 'seed'
        authorId: const Value(null),
        authorName: const Value(null),
        isFavorite: const Value(false),
        createdAt: Value(now),
        updatedAt: Value(now),
        lastSyncedAt: Value.absent(),
      );
    }).toList();

    await _db.workoutSetsDao.insertMultipleSets(workoutSets);
    _logger.i('Loaded ${workoutSets.length} workout sets');
  }

  /// Force reload seed data (for development/testing)
  Future<void> forceReload() async {
    _logger.w('Force reloading seed data...');

    // Clear existing data
    await _db.workoutSetsDao.deleteAllSets();

    // Reset seeded flag
    await _db.preferencesDao.setHasSeeded(false);

    // Reload
    await loadSeedDataIfNeeded();
  }

  /// Get seed data statistics
  Future<Map<String, int>> getStats() async {
    final exerciseCount = await _db.exercisesDao.countExercises();
    final seedSetCount = await _db.workoutSetsDao.countSetsBySource('seed');
    final userSetCount = await _db.workoutSetsDao.countSetsBySource('user');
    final communitySetCount = await _db.workoutSetsDao.countSetsBySource('community');

    return {
      'exercises': exerciseCount,
      'seed_sets': seedSetCount,
      'user_sets': userSetCount,
      'community_sets': communitySetCount,
      'total_sets': seedSetCount + userSetCount + communitySetCount,
    };
  }
}
