import 'package:logger/logger.dart';
import 'package:noctrafit/data/models/achievement_model.dart';
import 'package:noctrafit/data/repositories/achievements_repository.dart';

/// Service to initialize default achievements for new users
class DefaultAchievementsService {
  final AchievementsRepository _repo;
  final Logger _logger = Logger();

  DefaultAchievementsService(this._repo);

  /// Default achievements to create for all users
  static const List<Map<String, dynamic>> defaultAchievements = [
    {
      'id': 'first_workout',
      'title': 'Getting Started',
      'description': 'Complete your first workout',
      'icon': 'rocket',
      'goal_type': 'workouts',
      'goal_target': 1,
    },
    {
      'id': 'consistency_master',
      'title': 'Consistency Master',
      'description': 'Maintain a 7-day workout streak',
      'icon': 'flame',
      'goal_type': 'streak',
      'goal_target': 7,
    },
    {
      'id': 'century_club',
      'title': 'Century Club',
      'description': 'Complete 100 total workouts',
      'icon': 'trophy',
      'goal_type': 'workouts',
      'goal_target': 100,
    },
    {
      'id': 'time_warrior',
      'title': 'Time Warrior',
      'description': 'Exercise for 1000 minutes total',
      'icon': 'clock',
      'goal_type': 'duration',
      'goal_target': 1000,
    },
    {
      'id': 'iron_resolve',
      'title': 'Iron Resolve',
      'description': 'Reach a 30-day consecutive workout streak',
      'icon': 'medal',
      'goal_type': 'streak',
      'goal_target': 30,
    },
  ];

  /// Initialize default achievements for a new user
  /// Call this on user signup or first login
  Future<void> initializeDefaultAchievements(String userId) async {
    try {
      // Fetch existing achievements to avoid duplicates
      final existing = await _repo.getUserAchievements(userId).catchError((_) => <Achievement>[]);

      if (existing.isNotEmpty) {
        _logger.d('User $userId already has achievements, skipping initialization');
        return;
      }

      // Create default achievements
      final achievements = defaultAchievements
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

      // Batch create in Firestore
      await _repo.batchUpdateAchievements(userId, achievements);
      _logger.i('Initialized ${achievements.length} default achievements for user $userId');
    } catch (e) {
      _logger.e('Failed to initialize default achievements', error: e);
      // Non-fatal - continue app operation
    }
  }
}
