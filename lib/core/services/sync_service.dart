import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';

import '../../data/local/db/app_database.dart';
import '../../data/remote/firestore/sets_remote_datasource.dart';
import 'connectivity_service.dart';

/// Sync Service - Background synchronization with Firestore
///
/// Features:
/// - Background sync every 30 minutes when online
/// - Download catalog sets from Firestore
/// - Download community sets (paginated)
/// - Upload pending user sets from sync_queue
/// - Conflict resolution (remote wins for seed/community, local wins for user)
/// - Free tier compliant (sync every 30min, not realtime)
class SyncService {
  final AppDatabase _db;
  final SetsRemoteDataSource _remote;
  final ConnectivityService _connectivity;
  final Logger _logger;

  Timer? _syncTimer;
  bool _isSyncing = false;

  // Sync interval (30 minutes for free tier compliance)
  static const _syncInterval = Duration(minutes: 30);

  SyncService({
    required AppDatabase database,
    required SetsRemoteDataSource remote,
    required ConnectivityService connectivity,
    Logger? logger,
  })  : _db = database,
        _remote = remote,
        _connectivity = connectivity,
        _logger = logger ?? Logger();

  /// Start periodic background sync
  void startPeriodicSync() {
    _logger.i('Starting periodic sync (every ${_syncInterval.inMinutes} minutes)');

    // Cancel existing timer if any
    _syncTimer?.cancel();

    // Initial sync after 1 minute
    Future.delayed(const Duration(minutes: 1), () {
      if (_connectivity.isOnline) {
        syncAll();
      }
    });

    // Periodic sync
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      if (_connectivity.isOnline && !_isSyncing) {
        syncAll();
      } else {
        _logger.d('Skipping sync: ${_connectivity.isOnline ? 'already syncing' : 'offline'}');
      }
    });
  }

  /// Stop periodic background sync
  void stopPeriodicSync() {
    _logger.i('Stopping periodic sync');
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Sync all data (catalog + community + upload pending)
  Future<void> syncAll() async {
    if (_isSyncing) {
      _logger.w('Sync already in progress, skipping');
      return;
    }

    if (!_connectivity.isOnline) {
      _logger.w('Cannot sync: offline');
      return;
    }

    _isSyncing = true;
    _logger.i('Starting full sync...');

    try {
      // 1. Download catalog sets
      await _downloadCatalogSets();

      // 2. Download community sets (paginated)
      await _downloadCommunitySets();

      // 3. Upload pending user sets
      await _uploadPendingSets();

      _logger.i('Full sync completed successfully');
    } catch (e) {
      _logger.e('Sync failed: $e');
      // Don't rethrow - app continues offline
    } finally {
      _isSyncing = false;
    }
  }

  /// Download catalog sets from Firestore
  Future<void> _downloadCatalogSets() async {
    try {
      _logger.d('Downloading catalog sets...');

      // Check catalog version
      final remoteVersion = await _remote.fetchCatalogVersion();
      final localVersion =
          await _db.preferencesDao.getInt('catalog_version') ?? 0;

      if (remoteVersion <= localVersion) {
        _logger.d('Catalog already up to date (v$localVersion)');
        return;
      }

      // Fetch catalog sets
      final remoteSets = await _remote.fetchCatalogSets();
      _logger.d('Downloaded ${remoteSets.length} catalog sets');

      // Upsert to local database
      for (final remoteSet in remoteSets) {
        final workoutSet = WorkoutSet(
          id: 0, // Will be auto-assigned
          uuid: remoteSet['uuid'],
          name: remoteSet['name'],
          description: remoteSet['description'],
          difficulty: remoteSet['difficulty'],
          category: remoteSet['category'],
          estimatedMinutes: remoteSet['estimated_minutes'],
          exercises: remoteSet['exercises'],
          source: 'seed', // Catalog sets are treated as seed data
          authorId: remoteSet['author_id'],
          authorName: remoteSet['author_name'],
          isFavorite: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
        );

        await _db.workoutSetsDao.upsertSet(workoutSet);
      }

      // Update local catalog version
      await _db.preferencesDao.setInt('catalog_version', remoteVersion);

      _logger.i('Catalog sets synced successfully (v$remoteVersion)');
    } catch (e) {
      _logger.e('Failed to download catalog sets: $e');
      rethrow;
    }
  }

  /// Download community sets from Firestore (paginated)
  Future<void> _downloadCommunitySets() async {
    try {
      _logger.d('Downloading community sets...');

      // Fetch first page (50 sets)
      final remoteSets = await _remote.fetchCommunitySets(limit: 50);
      _logger.d('Downloaded ${remoteSets.length} community sets');

      // Upsert to local database
      for (final remoteSet in remoteSets) {
        final workoutSet = WorkoutSet(
          id: 0, // Will be auto-assigned
          uuid: remoteSet['uuid'],
          name: remoteSet['name'],
          description: remoteSet['description'],
          difficulty: remoteSet['difficulty'],
          category: remoteSet['category'],
          estimatedMinutes: remoteSet['estimated_minutes'],
          exercises: remoteSet['exercises'],
          source: 'community',
          authorId: remoteSet['author_id'],
          authorName: remoteSet['author_name'],
          isFavorite: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
        );

        await _db.workoutSetsDao.upsertSet(workoutSet);
      }

      _logger.i('Community sets synced successfully');
    } catch (e) {
      _logger.e('Failed to download community sets: $e');
      rethrow;
    }
  }

  /// Upload pending user sets from sync_queue
  Future<void> _uploadPendingSets() async {
    try {
      _logger.d('Uploading pending user sets...');

      // Get pending sync items (retry count < 3)
      final pendingItems = await _db.syncQueueDao.getRetryable();

      if (pendingItems.isEmpty) {
        _logger.d('No pending sets to upload');
        return;
      }

      _logger.d('Found ${pendingItems.length} pending sets to upload');

      for (final item in pendingItems) {
        try {
          final payload = jsonDecode(item.payload);

          if (item.operation == 'create') {
            // Upload to Firestore
            await _remote.uploadCommunitySet(
              uuid: payload['uuid'],
              name: payload['name'],
              description: payload['description'],
              difficulty: payload['difficulty'],
              category: payload['category'],
              estimatedMinutes: payload['estimated_minutes'],
              exercises: payload['exercises'],
              authorId: payload['author_id'],
              authorName: payload['author_name'],
            );

            // Update local record sync timestamp
            final localSet = await _db.workoutSetsDao.getSetByUuid(payload['uuid']);
            if (localSet != null) {
              final updatedSet = WorkoutSet(
                id: localSet.id,
                uuid: localSet.uuid,
                name: localSet.name,
                description: localSet.description,
                difficulty: localSet.difficulty,
                category: localSet.category,
                estimatedMinutes: localSet.estimatedMinutes,
                exercises: localSet.exercises,
                source: localSet.source,
                authorId: localSet.authorId,
                authorName: localSet.authorName,
                isFavorite: localSet.isFavorite,
                createdAt: localSet.createdAt,
                updatedAt: localSet.updatedAt,
                lastSyncedAt: DateTime.now(),
              );
              await _db.workoutSetsDao.upsertSet(updatedSet);
            }

            // Mark sync item as completed
            await _db.syncQueueDao.markCompleted(item.id);

            _logger.i('Uploaded set: ${payload['uuid']}');
          } else if (item.operation == 'update') {
            // Update on Firestore
            await _remote.updateCommunitySet(
              firestoreId: payload['firestore_id'],
              updates: {
                'name': payload['name'],
                'description': payload['description'],
                'difficulty': payload['difficulty'],
                'category': payload['category'],
                'estimated_minutes': payload['estimated_minutes'],
                'exercises': payload['exercises'],
              },
            );

            // Mark sync item as completed
            await _db.syncQueueDao.markCompleted(item.id);

            _logger.i('Updated set: ${payload['uuid']}');
          } else if (item.operation == 'delete') {
            // Delete from Firestore
            await _remote.deleteCommunitySet(
              firestoreId: payload['firestore_id'],
            );

            // Mark sync item as completed
            await _db.syncQueueDao.markCompleted(item.id);

            _logger.i('Deleted set: ${payload['uuid']}');
          }
        } catch (e) {
          _logger.e('Failed to sync item ${item.id}: $e');

          // Increment retry count
          await _db.syncQueueDao.incrementRetry(item.id);

          // Continue with next item
        }
      }

      _logger.i('Pending sets uploaded successfully');
    } catch (e) {
      _logger.e('Failed to upload pending sets: $e');
      rethrow;
    }
  }

  /// Force immediate sync (triggered by user action)
  Future<void> forceSyncNow() async {
    _logger.i('Force sync triggered by user');
    await syncAll();
  }

  /// Dispose resources
  void dispose() {
    stopPeriodicSync();
  }
}
