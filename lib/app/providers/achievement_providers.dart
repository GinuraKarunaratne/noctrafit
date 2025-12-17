import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noctrafit/app/providers/auth_provider.dart';
import 'package:noctrafit/core/services/achievement_unlock_service.dart';
import 'package:noctrafit/core/services/default_achievements_service.dart';
import 'package:noctrafit/data/models/achievement_model.dart';
import 'package:noctrafit/data/remote/firestore/achievements_remote_datasource.dart';
import 'package:noctrafit/data/repositories/achievements_repository.dart';
import 'package:noctrafit/app/providers/repository_providers.dart';

/// Provider for AchievementsRemoteDataSource
final achievementsRemoteDataSourceProvider = Provider<AchievementsRemoteDataSource>((ref) {
  return AchievementsRemoteDataSource();
});

/// Provider for AchievementsRepository
final achievementsRepositoryProvider = Provider<AchievementsRepository>((ref) {
  final remote = ref.watch(achievementsRemoteDataSourceProvider);
  return AchievementsRepository(remote);
});

/// Provider for AchievementUnlockService
final achievementUnlockServiceProvider = Provider<AchievementUnlockService>((ref) {
  final achievementsRepo = ref.watch(achievementsRepositoryProvider);
  final insightsRepo = ref.watch(insightsRepositoryProvider);
  return AchievementUnlockService(achievementsRepo, insightsRepo);
});

/// Provider for DefaultAchievementsService
final defaultAchievementsServiceProvider = Provider<DefaultAchievementsService>((ref) {
  final achievementsRepo = ref.watch(achievementsRepositoryProvider);
  return DefaultAchievementsService(achievementsRepo);
});

/// Stream provider for user achievements - Firestore-primary with local fallback
/// Always returns all achievements (locked and unlocked), never empty
final userAchievementsProvider = StreamProvider<List<Achievement>>((ref) async* {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    yield [];
    return;
  }

  final achievementsRepo = ref.watch(achievementsRepositoryProvider);
  final defaultService = ref.watch(defaultAchievementsServiceProvider);
  final userId = user.uid;

  try {
    // Initialize default achievements if user is new
    await defaultService.initializeDefaultAchievements(userId);

    // Fetch from Firestore (primary source)
    final achievements = await achievementsRepo.getUserAchievements(userId);
    
    // If no achievements (should not happen after initialization), return defaults
    if (achievements.isEmpty) {
      yield DefaultAchievementsService.defaultAchievements
          .map((data) => Achievement(
                id: data['id'] as String,
                title: data['title'] as String,
                description: data['description'] as String,
                icon: data['icon'] as String,
                isUnlocked: false,
                goalType: data['goal_type'] as String,
                goalTarget: data['goal_target'] as int,
                currentProgress: 0,
              ))
          .toList();
    } else {
      yield achievements;
    }

    // Auto-evaluate achievements when data loads
    final unlockService = ref.watch(achievementUnlockServiceProvider);
    await unlockService.evaluateAndUnlockAchievements(userId);

    // Re-fetch to get updated achievements
    final updatedAchievements = await achievementsRepo.getUserAchievements(userId);
    yield updatedAchievements.isEmpty ? achievements : updatedAchievements;
  } catch (e) {
    // Fallback to cache if Firestore fails
    final cached = achievementsRepo.getCachedAchievements(userId);
    if (cached.isNotEmpty) {
      yield cached;
    } else {
      // Last resort: show default template
      yield DefaultAchievementsService.defaultAchievements
          .map((data) => Achievement(
                id: data['id'] as String,
                title: data['title'] as String,
                description: data['description'] as String,
                icon: data['icon'] as String,
                isUnlocked: false,
                goalType: data['goal_type'] as String,
                goalTarget: data['goal_target'] as int,
                currentProgress: 0,
              ))
          .toList();
    }
  }
});

/// Get a specific achievement
final achievementProvider = Provider.family<Achievement?, String>((ref, achievementId) {
  final achievements = ref.watch(userAchievementsProvider).value ?? [];
  try {
    return achievements.firstWhere((a) => a.id == achievementId);
  } catch (_) {
    return null;
  }
});

/// Evaluate achievements (manual trigger)
final evaluateAchievementsProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  final service = ref.watch(achievementUnlockServiceProvider);
  await service.evaluateAndUnlockAchievements(user.uid);
});
