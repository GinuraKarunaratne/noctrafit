import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

/// Remote datasource for user-related Firestore operations
/// Handles favorites, achievements, and user profile data
class UserRemoteDataSource {
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  UserRemoteDataSource(this._firestore);

  // ========== Favorites Operations ==========

  /// Add a workout set to user's favorites
  /// Creates document: users/{uid}/favorites/{setUuid}
  Future<void> addFavorite(String userId, String setUuid) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(setUuid)
          .set({
        'added_at': FieldValue.serverTimestamp(),
      });
      _logger.i('Added favorite for user $userId: $setUuid');
    } catch (e) {
      _logger.e('Failed to add favorite', error: e);
      rethrow;
    }
  }

  /// Remove a workout set from user's favorites
  Future<void> removeFavorite(String userId, String setUuid) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(setUuid)
          .delete();
      _logger.i('Removed favorite for user $userId: $setUuid');
    } catch (e) {
      _logger.e('Failed to remove favorite', error: e);
      rethrow;
    }
  }

  /// Get all favorites for a user
  Future<List<String>> getFavorites(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      _logger.e('Failed to get favorites', error: e);
      return [];
    }
  }

  /// Check if a set is favorited by user
  Future<bool> isFavorite(String userId, String setUuid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(setUuid)
          .get();
      return doc.exists;
    } catch (e) {
      _logger.e('Failed to check favorite status', error: e);
      return false;
    }
  }

  // ========== User Profile Operations ==========

  /// Create or update user profile
  Future<void> upsertUserProfile({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'display_name': displayName,
        'last_login_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _logger.i('Upserted user profile: $userId');
    } catch (e) {
      _logger.e('Failed to upsert user profile', error: e);
      rethrow;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      _logger.e('Failed to get user profile', error: e);
      return null;
    }
  }

  // ========== Schedule Entries Operations ==========

  /// Sync schedule entry to Firestore
  Future<void> syncScheduleEntry({
    required String userId,
    required String entryUuid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedule_entries')
          .doc(entryUuid)
          .set(data, SetOptions(merge: true));
      _logger.d('Synced schedule entry: $entryUuid');
    } catch (e) {
      _logger.e('Failed to sync schedule entry', error: e);
      rethrow;
    }
  }

  /// Delete schedule entry from Firestore
  Future<void> deleteScheduleEntry(String userId, String entryUuid) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedule_entries')
          .doc(entryUuid)
          .delete();
      _logger.d('Deleted schedule entry: $entryUuid');
    } catch (e) {
      _logger.e('Failed to delete schedule entry', error: e);
      rethrow;
    }
  }

  // ========== Completion Logs Operations ==========

  /// Sync completion log to Firestore
  Future<void> syncCompletionLog({
    required String userId,
    required String logUuid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('completion_logs')
          .doc(logUuid)
          .set(data, SetOptions(merge: true));
      _logger.d('Synced completion log: $logUuid');
    } catch (e) {
      _logger.e('Failed to sync completion log', error: e);
      rethrow;
    }
  }

  // ========== Achievements Operations ==========

  /// Unlock an achievement for a user
  Future<void> unlockAchievement({
    required String userId,
    required String achievementId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .set({
        ...data,
        'unlocked_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _logger.i('Unlocked achievement for $userId: $achievementId');
    } catch (e) {
      _logger.e('Failed to unlock achievement', error: e);
      rethrow;
    }
  }

  /// Get all unlocked achievements for a user
  Future<List<Map<String, dynamic>>> getAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _logger.e('Failed to get achievements', error: e);
      return [];
    }
  }
}
