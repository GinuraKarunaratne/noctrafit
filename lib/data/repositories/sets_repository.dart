import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

import '../local/db/app_database.dart';
import '../local/db/daos/sync_queue_dao.dart';
import '../local/db/daos/workout_sets_dao.dart';

/// Repository for workout sets with offline-first architecture
/// ALWAYS loads from local SQLite first, syncs with Firestore in background
class SetsRepository {
  final WorkoutSetsDao _localDao;
  final SyncQueueDao _syncQueue;
  final Logger _logger = Logger();

  SetsRepository(this._localDao, this._syncQueue);

  // ========== Read Operations (Always from Local) ==========

  Future<List<WorkoutSet>> getAllSets() => _localDao.getAllSets();
  Stream<List<WorkoutSet>> watchAllSets() => _localDao.watchAllSets();

  Future<WorkoutSet?> getSetByUuid(String uuid) => _localDao.getSetByUuid(uuid);

  Future<List<WorkoutSet>> getSetsBySource(String source) =>
      _localDao.getSetsBySource(source);

  Stream<List<WorkoutSet>> watchSetsBySource(String source) =>
      _localDao.watchSetsBySource(source);

  Future<List<WorkoutSet>> getFavoriteSets() => _localDao.getFavoriteSets();
  Future<List<WorkoutSet>> searchSets(String query) => _localDao.searchSets(query);

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

  Future<List<WorkoutSet>> getSortedSets({
    required String sortBy,
    bool ascending = false,
  }) {
    return _localDao.getSetsSorted(sortBy: sortBy, ascending: ascending);
  }

  Future<List<WorkoutSet>> filterAndSearch({
    String? query,
    String? source,
    String? category,
    String? difficulty,
    bool? isFavorite,
    String sortBy = 'recent',
    bool ascending = false,
  }) async {
    var sets = await filterSets(
      source: source,
      category: category,
      difficulty: difficulty,
      isFavorite: isFavorite,
    );

    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      sets = sets.where((set) {
        return set.name.toLowerCase().contains(lowercaseQuery) ||
            (set.description?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    }

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
          final difficultyOrder = {
            'beginner': 0,
            'intermediate': 1,
            'advanced': 2
          };
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

    await _localDao.insertSet(companion);

    final createdSet = await _localDao.getSetByUuid(uuid);
    _logger.i('Created custom workout set: $name');
    return createdSet!;
  }

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

  Future<void> updateSet(WorkoutSet set) async {
    await _localDao.updateSet(set);

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

  Future<void> toggleFavorite(int id, bool isFavorite) =>
      _localDao.toggleFavorite(id, isFavorite);

  // ========== Delete Operations ==========

  Future<void> deleteSet(int id) async {
    final set = await _localDao.getSetById(id);
    if (set == null) return;

    await _localDao.deleteSet(id);

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

  /// ✅ Upsert set from Firestore (during sync)
  /// - tolerant to missing fields
  /// - accepts fallbackUuid (use doc.id or route uuid)
  Future<void> upsertFromFirestore(
    Map<String, dynamic> firestoreData, {
    String? fallbackUuid,
  }) async {
    try {
      final set = _deserializeSet(firestoreData, fallbackUuid: fallbackUuid);
      await _localDao.upsertSet(set);
      _logger.d('Upserted set from Firestore: ${set.name}');
    } catch (e, st) {
      _logger.e('Failed to upsert set from Firestore', error: e, stackTrace: st);
    }
  }

  Future<void> batchUpsertFromFirestore(
    List<Map<String, dynamic>> firestoreDataList,
  ) async {
    for (final data in firestoreDataList) {
      await upsertFromFirestore(data);
    }
    _logger.i('Batch upserted ${firestoreDataList.length} sets from Firestore');
  }

  // ========== Count & Stats ==========

  Future<int> countSets() => _localDao.countSets();
  Future<int> countSetsBySource(String source) => _localDao.countSetsBySource(source);

  // ========== Helpers ==========

  String _serializeSet(WorkoutSet set) {
    // ✅ safer JSON encoding (no manual multiline string)
    final map = <String, dynamic>{
      'uuid': set.uuid,
      'name': set.name,
      'description': set.description,
      'difficulty': set.difficulty,
      'category': set.category,
      'estimated_minutes': set.estimatedMinutes,
      // exercises is already JSON string in DB, keep as decoded if possible
      'exercises': (() {
        try {
          return jsonDecode(set.exercises);
        } catch (_) {
          return set.exercises;
        }
      })(),
      'source': set.source,
      'author_id': set.authorId,
      'author_name': set.authorName,
      'created_at': set.createdAt.toIso8601String(),
      'updated_at': set.updatedAt.toIso8601String(),
    };
    return jsonEncode(map);
  }

  // ---- robust parsing helpers ----
  String _s(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    final str = v.toString().trim();
    return str.isEmpty ? fallback : str;
  }

  int _i(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  DateTime _dt(dynamic v, {DateTime? fallback}) {
    if (v == null) return fallback ?? DateTime.now();

    if (v is DateTime) return v;

    // Firestore Timestamp without importing it directly
    try {
      if (v.runtimeType.toString() == 'Timestamp') {
        return (v as dynamic).toDate() as DateTime;
      }
    } catch (_) {}

    final parsed = DateTime.tryParse(v.toString());
    return parsed ?? (fallback ?? DateTime.now());
  }

  String _jsonString(dynamic v) {
    if (v == null) return '[]';
    if (v is String) return v;
    try {
      return jsonEncode(v);
    } catch (_) {
      return '[]';
    }
  }

  /// ✅ Safe deserializer (NO hard casts)
  WorkoutSet _deserializeSet(
    Map<String, dynamic> data, {
    String? fallbackUuid,
  }) {
    // uuid is required in Drift; fallback to doc.id / route uuid
    final uuid = _s(
      data['uuid'],
      fallback: _s(data['id'], fallback: _s(fallbackUuid, fallback: '')),
    );

    final safeUuid =
        uuid.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : uuid;

    final name = _s(data['name'], fallback: 'Untitled Workout');

    final description = data['description']?.toString();

    final difficulty = _s(data['difficulty'], fallback: 'intermediate');
    final category = _s(data['category'], fallback: 'hybrid');

    final estimatedMinutes = _i(
      data['estimated_minutes'],
      fallback: _i(data['estimatedMinutes'], fallback: 30),
    );

    final exercisesStr = _jsonString(data['exercises']);

    final source = _s(data['source'], fallback: 'community');

    final authorId = _s(
      data['author_id'],
      fallback: _s(data['authorId'], fallback: _s(data['author_uid'], fallback: '')),
    );
    final authorName = _s(
      data['author_name'],
      fallback: _s(data['authorName'], fallback: ''),
    );

    final createdAt = _dt(data['created_at'], fallback: DateTime.now());
    final updatedAt = _dt(data['updated_at'], fallback: createdAt);

    return WorkoutSet(
      id: 0, // auto assigned
      uuid: safeUuid,
      name: name,
      description: description,
      difficulty: difficulty,
      category: category,
      estimatedMinutes: estimatedMinutes,
      exercises: exercisesStr,
      source: source,
      authorId: authorId.isEmpty ? null : authorId,
      authorName: authorName.isEmpty ? null : authorName,
      isFavorite: false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastSyncedAt: DateTime.now(),
    );
  }
}
