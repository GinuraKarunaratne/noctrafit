import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:noctrafit/data/models/achievement_model.dart';

/// Remote data source for achievements - reads from Firestore
class AchievementsRemoteDataSource {
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  AchievementsRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch all achievements for a user from Firestore
  /// Achievements are stored at: users/{uid}/achievements/{achievementId}
  Future<List<Achievement>> fetchUserAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      final achievements = snapshot.docs
          .map((doc) => Achievement.fromFirestore(doc.id, doc.data()))
          .toList();

      _logger.d('Fetched ${achievements.length} achievements for user $userId');
      return achievements;
    } catch (e) {
      _logger.e('Failed to fetch achievements', error: e);
      rethrow;
    }
  }

  /// Update achievement unlock status in Firestore
  Future<void> updateAchievementStatus(
    String userId,
    String achievementId,
    bool isUnlocked,
    int? currentProgress,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .set(
        {
          'is_unlocked': isUnlocked,
          'current_progress': currentProgress,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      _logger.d('Updated achievement $achievementId for user $userId');
    } catch (e) {
      _logger.e('Failed to update achievement', error: e);
      rethrow;
    }
  }

  /// Batch update multiple achievements
  Future<void> batchUpdateAchievements(
    String userId,
    List<Achievement> achievements,
  ) async {
    try {
      final batch = _firestore.batch();
      for (final achievement in achievements) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .doc(achievement.id);
        batch.set(
          docRef,
          achievement.toFirestore(),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      _logger.d('Batch updated ${achievements.length} achievements');
    } catch (e) {
      _logger.e('Failed to batch update achievements', error: e);
      rethrow;
    }
  }
}
