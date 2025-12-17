import 'package:logger/logger.dart';
import 'package:noctrafit/data/models/achievement_model.dart';
import 'package:noctrafit/data/repositories/achievements_repository.dart';
import 'package:noctrafit/data/repositories/insights_repository.dart';

/// Service to evaluate and unlock achievements based on user progress
class AchievementUnlockService {
  final AchievementsRepository _achievementsRepo;
  final InsightsRepository _insightsRepo;
  final Logger _logger = Logger();

  AchievementUnlockService(
    this._achievementsRepo,
    this._insightsRepo,
  );

  /// Evaluate and unlock achievements for user
  /// This is called after workout completion or on profile load
  Future<void> evaluateAndUnlockAchievements(String userId) async {
    try {
      // Fetch current achievements
      final achievements = await _achievementsRepo.getUserAchievements(userId);
      final updatedAchievements = <Achievement>[];

      // Get user stats from Firestore (remote-primary)
      final totalWorkouts = await _insightsRepo.getTotalWorkoutsRemote(userId).catchError(
        (_) => 0, // Fallback to 0 if offline
      );
      final currentStreak = await _insightsRepo.getCurrentStreakRemote(userId).catchError(
        (_) => 0,
      );
      final totalMinutes = await _insightsRepo.getTotalMinutesThisMonthRemote(userId).catchError(
        (_) => 0,
      );

      _logger.d(
        'Evaluating achievements - totalWorkouts: $totalWorkouts, streak: $currentStreak, totalMinutes: $totalMinutes',
      );

      for (final achievement in achievements) {
        var updated = achievement;

        // Evaluate based on goal type
        switch (achievement.goalType) {
          case 'workouts':
            // Unlock when user completes X workouts
            if (totalWorkouts >= achievement.goalTarget) {
              updated = achievement.copyWith(isUnlocked: true);
            }
            updated = updated.copyWith(currentProgress: totalWorkouts);
            break;

          case 'streak':
            // Unlock when user has X-day streak
            if (currentStreak >= achievement.goalTarget) {
              updated = achievement.copyWith(isUnlocked: true);
            }
            updated = updated.copyWith(currentProgress: currentStreak);
            break;

          case 'duration':
            // Unlock when user completes X minutes
            if (totalMinutes >= achievement.goalTarget) {
              updated = achievement.copyWith(isUnlocked: true);
            }
            updated = updated.copyWith(currentProgress: totalMinutes);
            break;

          // Add more goal types as needed
          default:
            break;
        }

        updatedAchievements.add(updated);
      }

      // Batch update achievements in Firestore if any changed
      final changedAchievements = updatedAchievements.where((updated) {
        final original = achievements.firstWhere(
          (a) => a.id == updated.id,
          orElse: () => updated,
        );
        return updated.isUnlocked != original.isUnlocked ||
            updated.currentProgress != original.currentProgress;
      }).toList();

      if (changedAchievements.isNotEmpty) {
        await _achievementsRepo.batchUpdateAchievements(userId, changedAchievements);
        _logger.i('Unlocked ${changedAchievements.where((a) => a.isUnlocked).length} achievements');
      }
    } catch (e) {
      _logger.e('Failed to evaluate achievements', error: e);
      // Non-fatal: continue app operation
    }
  }
}
