import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noctrafit/app/providers/repository_providers.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/service_providers.dart';
import 'package:noctrafit/app/widgets/composite/stats_grid.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../app/theme/color_tokens.dart';

/// Provider for total workout count (lifetime)
final totalWorkoutsProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  final insights = ref.read(insightsRepositoryProvider);
  if (user != null) {
    // No dedicated remote total method, fetch remote logs and count
    final docs = await ref.read(userRemoteDataSourceProvider).fetchCompletionLogs(userId: user.uid);
    return docs.length;
  }
  return insights.getTotalWorkouts();
});

/// Provider for total minutes (lifetime)
final totalMinutesProvider = FutureProvider<int>((ref) async {
  final logs = await ref.read(insightsRepositoryProvider).getAllLogs();
  return logs.fold<int>(0, (sum, log) => sum + (log.durationSeconds ~/ 60));
});

/// Provider for current streak
final streakProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  final insights = ref.read(insightsRepositoryProvider);
  if (user != null) {
    return insights.getCurrentStreakRemote(user.uid);
  }
  return insights.getCurrentStreak();
});

/// Provider for average completion rate (all time)
final avgCompletionRateProvider = FutureProvider<double>((ref) async {
  final scheduleRepo = ref.read(scheduleRepositoryProvider);
  final allEntries = await scheduleRepo.getAllEntries();
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    // Compute from remote completion logs: total done exercises / total exercises
    final docs = await ref.read(userRemoteDataSourceProvider).fetchCompletionLogs(userId: user.uid);
    int totalDone = 0;
    int totalExercises = 0;
    for (final d in docs) {
      try {
        final ex = d['exercises_completed'];
        if (ex is List) {
          for (final e in ex) {
            if (e is Map) {
              final done = e['done'];
              if (done == true) totalDone++;
              totalExercises++;
            }
          }
        }
      } catch (_) {}
    }
    if (totalExercises == 0) return 0.0;
    return (totalDone / totalExercises) * 100.0;
  }

  if (allEntries.isEmpty) return 0.0;

  final completed = allEntries.where((e) => e.isCompleted).length;
  return (completed / allEntries.length) * 100;
});

/// Provider for activity heatmap data (past year)
final activityHeatmapProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  final insightsRepo = ref.read(insightsRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  final now = DateTime.now();
  final yearAgo = now.subtract(const Duration(days: 365));

  if (user != null) {
    // Fetch remote logs and aggregate by date
    final docs = await ref.read(userRemoteDataSourceProvider).fetchCompletionLogs(userId: user.uid, start: yearAgo, end: now);
    final Map<DateTime, int> countByDate = {};
    for (final d in docs) {
      try {
        final dt = DateTime.parse(d['completed_at'].toString());
        final dateOnly = DateTime(dt.year, dt.month, dt.day);
        countByDate[dateOnly] = (countByDate[dateOnly] ?? 0) + 1;
      } catch (_) {}
    }
    return countByDate;
  }

  return insightsRepo.getCompletionHeatmapData(yearAgo, now);
});

/// Provider for lifetime stats
final lifetimeStatsProvider = FutureProvider<List<StatData>>((ref) async {
  final totalWorkouts = await ref.watch(totalWorkoutsProvider.future);
  final totalMinutes = await ref.watch(totalMinutesProvider.future);
  final streak = await ref.watch(streakProvider.future);
  final avgCompletion = await ref.watch(avgCompletionRateProvider.future);

  return [
    StatData(
      value: totalWorkouts.toString(),
      label: 'Total Workouts',
      icon: TablerIcons.barbell,
      iconColor: ColorTokens.accent,
    ),
    StatData(
      value: totalMinutes.toStringAsFixed(0),
      label: 'Total Minutes',
      icon: TablerIcons.clock,
      iconColor: ColorTokens.info,
    ),
    StatData(
      value: streak.toString(),
      label: 'Current Streak',
      icon: TablerIcons.flame,
      iconColor: ColorTokens.warning,
    ),
    StatData(
      value: '${avgCompletion.toInt()}%',
      label: 'Avg Completion',
      icon: TablerIcons.chart_pie,
      iconColor: ColorTokens.success,
    ),
  ];
});
