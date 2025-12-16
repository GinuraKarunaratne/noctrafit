import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import 'firestore_client.dart';

/// Sets Remote Datasource - Firestore operations for workout sets
///
/// Features:
/// - Fetch catalog sets (app-provided)
/// - Fetch community sets (user-created, paginated)
/// - Upload user sets to community
/// - Update/delete own community sets
/// - Free tier compliant (no realtime listeners, uses get() only)
class SetsRemoteDataSource {
  final FirestoreClient _client;
  final Logger _logger;

  SetsRemoteDataSource({
    required FirestoreClient client,
    Logger? logger,
  })  : _client = client,
        _logger = logger ?? Logger();

  /// Fetch all catalog sets
  /// Catalog sets are app-provided workout sets (read-only)
  Future<List<Map<String, dynamic>>> fetchCatalogSets() async {
    return _client.executeOperation(
      operation: () async {
        final snapshot = await _client.catalogSets
            .orderBy('created_at', descending: true)
            .get();

        return snapshot.docs.map((doc) {
          return {
            ...doc.data(),
            'firestore_id': doc.id,
          };
        }).toList();
      },
      operationName: 'fetchCatalogSets',
    );
  }

  /// Fetch catalog version from metadata
  /// Returns version number to check if catalog needs updating
  Future<int> fetchCatalogVersion() async {
    return _client.executeOperation(
      operation: () async {
        final doc = await _client.metadata.doc('catalog_version').get();

        if (!doc.exists) {
          _logger.w('Catalog version document not found, returning 0');
          return 0;
        }

        return (doc.data()?['version'] as int?) ?? 0;
      },
      operationName: 'fetchCatalogVersion',
    );
  }

  /// Fetch community sets with pagination
  /// Paginated to comply with free tier limits (50 per page)
  Future<List<Map<String, dynamic>>> fetchCommunitySets({
    int limit = 50,
    DocumentSnapshot? lastDocument,
    String? category,
    String? difficulty,
  }) async {
    return _client.executeOperation(
      operation: () async {
        Query<Map<String, dynamic>> query = _client.communitySets
            .orderBy('created_at', descending: true);

        // Apply filters
        if (category != null) {
          query = query.where('category', isEqualTo: category);
        }
        if (difficulty != null) {
          query = query.where('difficulty', isEqualTo: difficulty);
        }

        // Apply pagination
        query = query.limit(limit);
        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }

        final snapshot = await query.get();

        return snapshot.docs.map((doc) {
          return {
            ...doc.data(),
            'firestore_id': doc.id,
          };
        }).toList();
      },
      operationName: 'fetchCommunitySets',
    );
  }

  /// Upload user set to community
  /// Creates a new document in community_sets collection
  Future<String> uploadCommunitySet({
    required String uuid,
    required String name,
    required String description,
    required String difficulty,
    required String category,
    required int estimatedMinutes,
    required String exercises, // JSON string
    required String authorId,
    required String authorName,
  }) async {
    return _client.executeOperation(
      operation: () async {
        final data = {
          'uuid': uuid,
          'name': name,
          'description': description,
          'difficulty': difficulty,
          'category': category,
          'estimated_minutes': estimatedMinutes,
          'exercises': exercises,
          'author_id': authorId,
          'author_name': authorName,
          'downloads': 0,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };

        final docRef = await _client.communitySets.add(data);
        _logger.i('Uploaded community set: $uuid (Firestore ID: ${docRef.id})');

        return docRef.id;
      },
      operationName: 'uploadCommunitySet',
    );
  }

  /// Update existing community set
  /// Only author can update their own sets (enforced by security rules)
  Future<void> updateCommunitySet({
    required String firestoreId,
    required Map<String, dynamic> updates,
  }) async {
    return _client.executeOperation(
      operation: () async {
        final data = {
          ...updates,
          'updated_at': FieldValue.serverTimestamp(),
        };

        await _client.communitySets.doc(firestoreId).update(data);
        _logger.i('Updated community set: $firestoreId');
      },
      operationName: 'updateCommunitySet',
    );
  }

  /// Delete community set
  /// Only author can delete their own sets (enforced by security rules)
  Future<void> deleteCommunitySet({
    required String firestoreId,
  }) async {
    return _client.executeOperation(
      operation: () async {
        await _client.communitySets.doc(firestoreId).delete();
        _logger.i('Deleted community set: $firestoreId');
      },
      operationName: 'deleteCommunitySet',
    );
  }

  /// Increment downloads count for a community set
  /// Called when a user adds a community set to their library
  Future<void> incrementDownloads({
    required String firestoreId,
  }) async {
    return _client.executeOperation(
      operation: () async {
        await _client.communitySets.doc(firestoreId).update({
          'downloads': FieldValue.increment(1),
        });
        _logger.d('Incremented downloads for set: $firestoreId');
      },
      operationName: 'incrementDownloads',
    );
  }

  /// Search community sets by name
  /// Note: Firestore doesn't support full-text search, this is a basic prefix search
  Future<List<Map<String, dynamic>>> searchCommunitySets({
    required String searchQuery,
    int limit = 50,
  }) async {
    return _client.executeOperation(
      operation: () async {
        // Basic prefix search (Firestore limitation)
        // For production, consider using Algolia or similar for full-text search
        final snapshot = await _client.communitySets
            .orderBy('name')
            .startAt([searchQuery])
            .endAt(['$searchQuery\uf8ff'])
            .limit(limit)
            .get();

        return snapshot.docs.map((doc) {
          return {
            ...doc.data(),
            'firestore_id': doc.id,
          };
        }).toList();
      },
      operationName: 'searchCommunitySets',
    );
  }

  /// Fetch sets by author ID
  /// Get all community sets created by a specific user
  Future<List<Map<String, dynamic>>> fetchSetsByAuthor({
    required String authorId,
    int limit = 50,
  }) async {
    return _client.executeOperation(
      operation: () async {
        final snapshot = await _client.communitySets
            .where('author_id', isEqualTo: authorId)
            .orderBy('created_at', descending: true)
            .limit(limit)
            .get();

        return snapshot.docs.map((doc) {
          return {
            ...doc.data(),
            'firestore_id': doc.id,
          };
        }).toList();
      },
      operationName: 'fetchSetsByAuthor',
    );
  }

  /// Fetch a single community set by its UUID field
  Future<Map<String, dynamic>?> fetchCommunitySetByUuid({
    required String uuid,
  }) async {
    return _client.executeOperation(
      operation: () async {
        final snapshot = await _client.communitySets
            .where('uuid', isEqualTo: uuid)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) return null;
        final doc = snapshot.docs.first;
        return {
          ...doc.data(),
          'firestore_id': doc.id,
        };
      },
      operationName: 'fetchCommunitySetByUuid',
    );
  }

  /// Batch upload multiple sets
  /// Useful for initial catalog population
  Future<void> batchUploadCatalogSets({
    required List<Map<String, dynamic>> sets,
  }) async {
    return _client.executeOperation(
      operation: () async {
        final batch = _client.batch();

        for (final set in sets) {
          final docRef = _client.catalogSets.doc();
          batch.set(docRef, {
            ...set,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
        _logger.i('Batch uploaded ${sets.length} catalog sets');
      },
      operationName: 'batchUploadCatalogSets',
    );
  }
}
