import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noctrafit/app/providers/repository_providers.dart';
import 'package:noctrafit/app/widgets/composite/stats_grid.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../app/theme/color_tokens.dart';

/// Provider for total workout count (lifetime)
final totalWorkoutsProvider = FutureProvider<int>((ref) async {
  return ref.read(insightsRepositoryProvider).getTotalWorkouts();
});

/// Provider for total minutes (lifetime)
final totalMinutesProvider = FutureProvider<int>((ref) async {
  final logs = await ref.read(insightsRepositoryProvider).getAllLogs();
  return logs.fold<int>(0, (sum, log) => sum + (log.durationSeconds ~/ 60));
});

/// Provider for current streak
final streakProvider = FutureProvider<int>((ref) async {
  return ref.read(insightsRepositoryProvider).getCurrentStreak();
});

/// Provider for average completion rate (all time)
final avgCompletionRateProvider = FutureProvider<double>((ref) async {
  final scheduleRepo = ref.read(scheduleRepositoryProvider);
  final allEntries = await scheduleRepo.getAllEntries();

  if (allEntries.isEmpty) return 0.0;

  final completed = allEntries.where((e) => e.isCompleted).length;
  return (completed / allEntries.length) * 100;
});

/// Provider for activity heatmap data (past year)
final activityHeatmapProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  final insightsRepo = ref.read(insightsRepositoryProvider);
  final now = DateTime.now();
  final yearAgo = now.subtract(const Duration(days: 365));

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
