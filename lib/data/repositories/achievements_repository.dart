import 'package:logger/logger.dart';
import 'package:noctrafit/data/models/achievement_model.dart';
import 'package:noctrafit/data/remote/firestore/achievements_remote_datasource.dart';

/// Repository for achievements with Firestore-primary, local fallback
class AchievementsRepository {
  final AchievementsRemoteDataSource _remote;
  final Logger _logger = Logger();

  /// In-memory cache for achievements
  final Map<String, List<Achievement>> _cache = {};

  AchievementsRepository(this._remote);

  /// Get achievements for user - tries Firestore first, falls back to cache
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      // Try remote first
      final achievements = await _remote.fetchUserAchievements(userId);
      _cache[userId] = achievements;
      return achievements;
    } catch (e) {
      _logger.w('Failed to fetch from Firestore, using cache', error: e);
      // Return cached achievements if available
      return _cache[userId] ?? [];
    }
  }

  /// Get cached achievements (for offline use)
  List<Achievement> getCachedAchievements(String userId) {
    return _cache[userId] ?? [];
  }

  /// Update achievement and sync to Firestore
  Future<void> updateAchievementStatus(
    String userId,
    String achievementId,
    bool isUnlocked,
    int? currentProgress,
  ) async {
    try {
      // Update in cache first (optimistic)
      if (_cache[userId] != null) {
        final idx = _cache[userId]!.indexWhere((a) => a.id == achievementId);
        if (idx >= 0) {
          _cache[userId]![idx] = _cache[userId]![idx].copyWith(
            isUnlocked: isUnlocked,
            currentProgress: currentProgress,
          );
        }
      }

      // Sync to Firestore
      await _remote.updateAchievementStatus(
        userId,
        achievementId,
        isUnlocked,
        currentProgress,
      );
      _logger.d('Updated achievement $achievementId for user $userId');
    } catch (e) {
      _logger.e('Failed to update achievement', error: e);
      rethrow;
    }
  }

  /// Batch update achievements
  Future<void> batchUpdateAchievements(
    String userId,
    List<Achievement> achievements,
  ) async {
    try {
      // Update cache first
      _cache[userId] = achievements;

      // Sync to Firestore
      await _remote.batchUpdateAchievements(userId, achievements);
      _logger.d('Batch updated ${achievements.length} achievements');
    } catch (e) {
      _logger.e('Failed to batch update achievements', error: e);
      rethrow;
    }
  }

  /// Clear cache (useful for testing or logout)
  void clearCache() {
    _cache.clear();
  }
}
