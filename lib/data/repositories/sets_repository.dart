import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import '../local/db/app_database.dart';
import '../local/db/daos/workout_sets_dao.dart';
import '../local/db/daos/sync_queue_dao.dart';

/// Repository for workout sets with offline-first architecture
/// ALWAYS loads from local SQLite first, syncs with Firestore in background
class SetsRepository {
  final WorkoutSetsDao _localDao;
  final SyncQueueDao _syncQueue;
  final Logger _logger = Logger();

  SetsRepository(this._localDao, this._syncQueue);

  // ========== Read Operations (Always from Local) ==========

  /// Get all workout sets (offline-first)
  Future<List<WorkoutSet>> getAllSets() {
    return _localDao.getAllSets();
  }

  /// Watch all workout sets (stream)
  Stream<List<WorkoutSet>> watchAllSets() {
    return _localDao.watchAllSets();
  }

  /// Get workout set by UUID
  Future<WorkoutSet?> getSetByUuid(String uuid) {
    return _localDao.getSetByUuid(uuid);
  }

  /// Get sets by source (seed, user, community)
  Future<List<WorkoutSet>> getSetsBySource(String source) {
    return _localDao.getSetsBySource(source);
  }

  /// Watch sets by source (stream)
  Stream<List<WorkoutSet>> watchSetsBySource(String source) {
    return _localDao.watchSetsBySource(source);
  }

  /// Get favorite sets
  Future<List<WorkoutSet>> getFavoriteSets() {
    return _localDao.getFavoriteSets();
  }

  /// Search sets by query
  Future<List<WorkoutSet>> searchSets(String query) {
    return _localDao.searchSets(query);
  }

  /// Get sets with filters
  Future<List<WorkoutSet>> filterSets({
    String? source,
    String? category,
    String? difficulty,
    bool? isFavorite,
  }) {
    return _localDao.getSetsByFilter(
      source: source,
      category: category,
      difficulty: difficulty,
      isFavorite: isFavorite,
    );
  }

  /// Get sets sorted
  Future<List<WorkoutSet>> getSortedSets({
    required String sortBy,
    bool ascending = false,
  }) {
    return _localDao.getSetsSorted(sortBy: sortBy, ascending: ascending);
  }

  /// Combined filter and search
  Future<List<WorkoutSet>> filterAndSearch({
    String? query,
    String? source,
    String? category,
    String? difficulty,
    bool? isFavorite,
    String sortBy = 'recent',
    bool ascending = false,
  }) async {
    // Get filtered sets
    var sets = await filterSets(
      source: source,
      category: category,
      difficulty: difficulty,
      isFavorite: isFavorite,
    );

    // Apply search if query provided
    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      sets = sets.where((set) {
        return set.name.toLowerCase().contains(lowercaseQuery) ||
            (set.description?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    }

    // Apply sorting
    sets.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'duration':
          comparison = a.estimatedMinutes.compareTo(b.estimatedMinutes);
          break;
        case 'difficulty':
          final difficultyOrder = {'beginner': 0, 'intermediate': 1, 'advanced': 2};
          comparison = (difficultyOrder[a.difficulty] ?? 0)
              .compareTo(difficultyOrder[b.difficulty] ?? 0);
          break;
        case 'recent':
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return ascending ? comparison : -comparison;
    });

    return sets;
  }

  // ========== Create Operations ==========

  /// Create a new custom workout set (user-created)
  /// Saves locally first, queues for Firestore sync
  Future<WorkoutSet> createCustomSet({
    required String name,
    required String description,
    required String difficulty,
    required String category,
    required int estimatedMinutes,
    required String exercisesJson,
    String? authorName,
  }) async {
    final now = DateTime.now();

    // Generate UUID
    final uuid = DateTime.now().millisecondsSinceEpoch.toString();

    final companion = WorkoutSetsCompanion(
      uuid: Value(uuid),
      name: Value(name),
      description: Value(description),
      difficulty: Value(difficulty),
      category: Value(category),
      estimatedMinutes: Value(estimatedMinutes),
      exercises: Value(exercisesJson),
      source: const Value('user'),
      authorId: const Value(null),
      authorName: Value(authorName),
      isFavorite: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    // Save locally FIRST (offline-first)
    await _localDao.insertSet(companion);

    // Get the created set
    final createdSet = await _localDao.getSetByUuid(uuid);

    _logger.i('Created custom workout set: $name');
    return createdSet!;
  }

  /// Queue workout set for community upload
  Future<void> queueForCommunityUpload(WorkoutSet set) async {
    await _syncQueue.enqueue(
      entityType: 'workout_set',
      entityUuid: set.uuid,
      operation: 'create',
      payload: _serializeSet(set),
    );
    _logger.i('Queued set for community upload: ${set.name}');
  }

  // ========== Update Operations ==========

  /// Update a workout set
  Future<void> updateSet(WorkoutSet set) async {
    await _localDao.updateSet(set);

    // If user-created, queue for sync
    if (set.source == 'user') {
      await _syncQueue.enqueue(
        entityType: 'workout_set',
        entityUuid: set.uuid,
        operation: 'update',
        payload: _serializeSet(set),
      );
    }

    _logger.i('Updated workout set: ${set.name}');
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(int id, bool isFavorite) {
    return _localDao.toggleFavorite(id, isFavorite);
  }

  // ========== Delete Operations ==========

  /// Delete a workout set
  Future<void> deleteSet(int id) async {
    final set = await _localDao.getSetById(id);
    if (set == null) return;

    await _localDao.deleteSet(id);

    // If user-created, queue for deletion sync
    if (set.source == 'user') {
      await _syncQueue.enqueue(
        entityType: 'workout_set',
        entityUuid: set.uuid,
        operation: 'delete',
        payload: _serializeSet(set),
      );
    }

    _logger.i('Deleted workout set: ${set.name}');
  }

  // ========== Sync Operations (Background) ==========

  /// Upsert set from Firestore (during sync)
  Future<void> upsertFromFirestore(Map<String, dynamic> firestoreData) async {
    try {
      final set = _deserializeSet(firestoreData);
      await _localDao.upsertSet(set);
      _logger.d('Upserted set from Firestore: ${set.name}');
    } catch (e) {
      _logger.e('Failed to upsert set from Firestore', error: e);
    }
  }

  /// Batch upsert multiple sets from Firestore
  Future<void> batchUpsertFromFirestore(List<Map<String, dynamic>> firestoreDataList) async {
    for (final data in firestoreDataList) {
      await upsertFromFirestore(data);
    }
    _logger.i('Batch upserted ${firestoreDataList.length} sets from Firestore');
  }

  // ========== Count & Stats ==========

  Future<int> countSets() {
    return _localDao.countSets();
  }

  Future<int> countSetsBySource(String source) {
    return _localDao.countSetsBySource(source);
  }

  // ========== Helpers ==========

  String _serializeSet(WorkoutSet set) {
    // Convert to JSON-serializable map
    return '''
    {
      "uuid": "${set.uuid}",
      "name": "${set.name}",
      "description": "${set.description ?? ''}",
      "difficulty": "${set.difficulty}",
      "category": "${set.category}",
      "estimated_minutes": ${set.estimatedMinutes},
      "exercises": ${set.exercises},
      "source": "${set.source}",
      "author_id": "${set.authorId ?? ''}",
      "author_name": "${set.authorName ?? ''}",
      "created_at": "${set.createdAt.toIso8601String()}",
      "updated_at": "${set.updatedAt.toIso8601String()}"
    }
    ''';
  }

  WorkoutSet _deserializeSet(Map<String, dynamic> data) {
    return WorkoutSet(
      id: 0, // Will be auto-assigned
      uuid: data['uuid'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      difficulty: data['difficulty'] as String,
      category: data['category'] as String,
      estimatedMinutes: data['estimated_minutes'] as int,
      exercises: data['exercises'] as String,
      source: data['source'] as String,
      authorId: data['author_id'] as String?,
      authorName: data['author_name'] as String?,
      isFavorite: false,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
      lastSyncedAt: DateTime.now(),
    );
  }
}
