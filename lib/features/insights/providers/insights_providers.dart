import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noctrafit/app/providers/repository_providers.dart';
import '../../../data/local/db/app_database.dart';
import '../../../app/providers/auth_provider.dart';
import 'package:noctrafit/app/widgets/composite/luminous_chart_card.dart';
import 'package:noctrafit/app/widgets/composite/stats_grid.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../app/theme/color_tokens.dart';

/// Provider for monthly workout count
final monthlyWorkoutsProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  final repo = ref.read(insightsRepositoryProvider);
  if (user != null) {
    return repo.getWorkoutsThisMonthRemote(user.uid);
  }
  return repo.getWorkoutsThisMonth();
});

/// Provider for monthly total minutes
final monthlyMinutesProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  final repo = ref.read(insightsRepositoryProvider);
  if (user != null) {
    return repo.getTotalMinutesThisMonthRemote(user.uid);
  }
  return repo.getTotalMinutesThisMonth();
});

/// Provider for current streak
final currentStreakProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  final repo = ref.read(insightsRepositoryProvider);
  if (user != null) return repo.getCurrentStreakRemote(user.uid);
  return repo.getCurrentStreak();
});

/// Provider for completion rate this month
final completionRateProvider = FutureProvider<double>((ref) async {
  final scheduleRepo = ref.read(scheduleRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 1);
  final user = ref.watch(currentUserProvider);
  final insightsRepo = ref.read(insightsRepositoryProvider);

  if (user != null) {
    // Compute from remote completion logs using per-exercise flags
    final docs = await insightsRepo.getLogsInRangeRemote(user.uid, startOfMonth, endOfMonth);
    int totalDone = 0;
    int totalExercises = 0;
    for (final d in docs) {
      try {
        final ex = d['exercises_completed'];
        if (ex is List) {
          for (final e in ex) {
            if (e is Map) {
              if (e['done'] == true) totalDone++;
              totalExercises++;
            }
          }
        }
      } catch (_) {}
    }
    if (totalExercises == 0) return 0.0;
    return (totalDone / totalExercises) * 100.0;
  }

  final scheduled = await scheduleRepo.getEntriesInRange(startOfMonth, endOfMonth);
  if (scheduled.isEmpty) return 0.0;

  final completed = scheduled.where((e) => e.isCompleted).length;
  return (completed / scheduled.length) * 100;
});

/// Provider for weekly chart data (last 7 days)
final weeklyChartDataProvider = FutureProvider<List<ChartDataPoint>>((ref) async {
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: 6));
  final user = ref.watch(currentUserProvider);
  final repo = ref.read(insightsRepositoryProvider);
  final logs = user != null
      ? (await repo.getLogsInRangeRemote(user.uid, startOfWeek, now)).map((d) {
          final completedAt = DateTime.tryParse(d['completed_at']?.toString() ?? '') ?? DateTime.now();
          final startedAt = DateTime.tryParse(d['started_at']?.toString() ?? '') ?? completedAt.subtract(Duration(seconds: d['duration_seconds'] is int ? d['duration_seconds'] as int : int.tryParse(d['duration_seconds']?.toString() ?? '0') ?? 0));
          final createdAt = DateTime.tryParse(d['created_at']?.toString() ?? '') ?? completedAt;
          return CompletionLog(
            id: 0,
            uuid: d['uuid']?.toString() ?? '',
            workoutSetId: d['workout_set_id'] is int ? d['workout_set_id'] as int : null,
            startedAt: startedAt,
            completedAt: completedAt,
            durationSeconds: d['duration_seconds'] is int ? d['duration_seconds'] as int : int.tryParse(d['duration_seconds']?.toString() ?? '0') ?? 0,
            exercisesCompleted: d['exercises_completed'] is String ? d['exercises_completed'] as String : (d['exercises_completed'] is List ? d['exercises_completed'].toString() : ''),
            notes: null,
            createdAt: createdAt,
          );
        }).toList()
      : await repo.getLogsInRange(startOfWeek, now);

  // Group by day
  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final counts = List<int>.filled(7, 0);

  for (final log in logs) {
    final daysDiff = log.completedAt.difference(startOfWeek).inDays;
    if (daysDiff >= 0 && daysDiff < 7) {
      counts[daysDiff]++;
    }
  }

  return List.generate(7, (i) {
    final date = startOfWeek.add(Duration(days: i));
    final dayLabel = days[date.weekday - 1];
    return ChartDataPoint(value: counts[i].toDouble(), label: dayLabel);
  });
});

/// Provider for monthly chart data (last 4 weeks in minutes)
final monthlyChartDataProvider = FutureProvider<List<ChartDataPoint>>((ref) async {
  final insightsRepo = ref.read(insightsRepositoryProvider);
  final now = DateTime.now();

  final weeks = <ChartDataPoint>[];
  for (int i = 3; i >= 0; i--) {
    final weekEnd = now.subtract(Duration(days: i * 7));
    final weekStart = weekEnd.subtract(const Duration(days: 7));

    final logs = await insightsRepo.getLogsInRange(weekStart, weekEnd);
    final totalMinutes = logs.fold<int>(0, (sum, log) => sum + (log.durationSeconds ~/ 60));

    weeks.add(ChartDataPoint(value: totalMinutes.toDouble(), label: 'W${4 - i}'));
  }

  return weeks;
});

/// Provider for category breakdown
final categoryBreakdownProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final insightsRepo = ref.read(insightsRepositoryProvider);
  final setsRepo = ref.read(setsRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  final logs = await insightsRepo.getLogsInRange(startOfMonth, now);

  if (logs.isEmpty) {
    return [];
  }

  // Get all sets to determine categories
  final allSets = await setsRepo.getAllSets();
  final setsById = {for (var set in allSets) set.id: set};

  // Count workouts by category
  final categoryCounts = <String, int>{};
  for (final log in logs) {
    if (log.workoutSetId != null) {
      final set = setsById[log.workoutSetId];
      if (set != null) {
        categoryCounts[set.category] = (categoryCounts[set.category] ?? 0) + 1;
      }
    }
  }

  final totalWorkouts = logs.length;

  // Build category breakdown
  final breakdown = <Map<String, dynamic>>[];
  categoryCounts.forEach((category, count) {
    final percentage = ((count / totalWorkouts) * 100).round();
    breakdown.add({
      'name': category[0].toUpperCase() + category.substring(1),
      'workouts': count,
      'percentage': percentage,
      'icon': _getCategoryIcon(category),
    });
  });

  // Sort by count descending
  breakdown.sort((a, b) => (b['workouts'] as int).compareTo(a['workouts'] as int));

  return breakdown;
});

/// Provider for monthly stats
final monthlyStatsProvider = FutureProvider<List<StatData>>((ref) async {
  final workouts = await ref.watch(monthlyWorkoutsProvider.future);
  final minutes = await ref.watch(monthlyMinutesProvider.future);
  final streak = await ref.watch(currentStreakProvider.future);
  final completionRate = await ref.watch(completionRateProvider.future);

  return [
    StatData(
      value: workouts.toString(),
      label: 'Workouts',
      icon: TablerIcons.barbell,
      trend: null,
    ),
    StatData(
      value: minutes.toString(),
      label: 'Minutes',
      icon: TablerIcons.clock,
      trend: null,
    ),
    StatData(
      value: streak.toString(),
      label: 'Streak',
      icon: TablerIcons.flame,
      iconColor: ColorTokens.warning,
      trend: null,
    ),
    StatData(
      value: '${completionRate.toInt()}%',
      label: 'Completion',
      icon: TablerIcons.chart_pie,
      iconColor: ColorTokens.success,
      trend: null,
    ),
  ];
});

IconData _getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'cardio':
      return TablerIcons.run;
    case 'strength':
      return TablerIcons.barbell;
    case 'flexibility':
      return TablerIcons.yoga;
    default:
      return TablerIcons.activity;
  }
}
