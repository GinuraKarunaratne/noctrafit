import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  // ========== Create/Enqueue ==========
  /// Enqueue a new sync operation
  Future<int> enqueue({
    required String entityType,
    required String entityUuid,
    required String operation,
    required String payload,
  }) {
    return into(syncQueue).insert(SyncQueueCompanion(
      entityType: Value(entityType),
      entityUuid: Value(entityUuid),
      operation: Value(operation),
      payload: Value(payload),
      createdAt: Value(DateTime.now()),
      retryCount: const Value(0),
    ));
  }

  // ========== Read ==========
  /// Get all pending sync items
  Future<List<SyncQueueItem>> getAllPending() {
    return (select(syncQueue)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
  }

  /// Get pending items by entity type
  Future<List<SyncQueueItem>> getPendingByType(String entityType) {
    return (select(syncQueue)
          ..where((t) => t.entityType.equals(entityType))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Get pending items for a specific entity
  Future<List<SyncQueueItem>> getPendingForEntity(
    String entityType,
    String entityUuid,
  ) {
    return (select(syncQueue)
          ..where((t) =>
              t.entityType.equals(entityType) & t.entityUuid.equals(entityUuid))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Get items with retry count below threshold
  Future<List<SyncQueueItem>> getRetryable({int maxRetries = 5}) {
    return (select(syncQueue)
          ..where((t) => t.retryCount.isSmallerThanValue(maxRetries))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Get items that have exceeded max retries
  Future<List<SyncQueueItem>> getFailedItems({int maxRetries = 5}) {
    return (select(syncQueue)
          ..where((t) => t.retryCount.isBiggerOrEqualValue(maxRetries))
          ..orderBy([(t) => OrderingTerm.desc(t.retryCount)]))
        .get();
  }

  // ========== Update ==========
  /// Increment retry count for an item
  Future<void> incrementRetry(int id, {String? errorMessage}) async {
    final item = await (select(syncQueue)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (item == null) return;

    await (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        retryCount: Value(item.retryCount + 1),
        lastError: Value(errorMessage),
      ),
    );
  }

  /// Update error message
  Future<void> updateError(int id, String errorMessage) async {
    await (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        lastError: Value(errorMessage),
      ),
    );
  }

  // ========== Delete ==========
  /// Mark item as completed (delete from queue)
  Future<int> markCompleted(int id) {
    return (delete(syncQueue)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all items for an entity
  Future<void> deleteForEntity(String entityType, String entityUuid) {
    return (delete(syncQueue)
          ..where((t) =>
              t.entityType.equals(entityType) & t.entityUuid.equals(entityUuid)))
        .go();
  }

  /// Clear all pending items
  Future<void> clearAll() {
    return delete(syncQueue).go();
  }

  /// Delete failed items (exceeded max retries)
  Future<void> clearFailedItems({int maxRetries = 5}) {
    return (delete(syncQueue)..where((t) => t.retryCount.isBiggerOrEqualValue(maxRetries))).go();
  }

  // ========== Count ==========
  Future<int> countPending() async {
    final count = syncQueue.id.count();
    final query = selectOnly(syncQueue)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> countByType(String entityType) async {
    final count = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([count])
      ..where(syncQueue.entityType.equals(entityType));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
