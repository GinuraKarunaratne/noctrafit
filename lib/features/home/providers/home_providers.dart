import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noctrafit/app/providers/repository_providers.dart';
import 'package:noctrafit/app/widgets/composite/stats_grid.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../app/theme/color_tokens.dart';

final weeklyWorkoutsProvider = FutureProvider<int>((ref) async {
  return ref.read(insightsRepositoryProvider).getWorkoutsThisWeek();
});

final weeklyMinutesProvider = FutureProvider<int>((ref) async {
  return ref.read(insightsRepositoryProvider).getTotalMinutesThisWeek();
});

final weeklyStreakProvider = FutureProvider<int>((ref) async {
  return ref.read(insightsRepositoryProvider).getCurrentStreak();
});

final weeklyCompletionProvider = FutureProvider<double>((ref) async {
  final scheduleRepo = ref.read(scheduleRepositoryProvider);
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));

  final scheduled = await scheduleRepo.getEntriesInRange(startOfWeek, endOfWeek);
  if (scheduled.isEmpty) return 0.0;

  final completed = scheduled.where((e) => e.isCompleted).length;
  return (completed / scheduled.length) * 100;
});

final weeklyStatsProvider = FutureProvider<List<StatData>>((ref) async {
  final workouts = await ref.watch(weeklyWorkoutsProvider.future);
  final minutes = await ref.watch(weeklyMinutesProvider.future);
  final streak = await ref.watch(weeklyStreakProvider.future);
  final completion = await ref.watch(weeklyCompletionProvider.future);

  return [
    StatData(value: workouts.toString(), label: 'Workouts', icon: TablerIcons.barbell, iconColor: ColorTokens.accent),
    StatData(value: minutes.toString(), label: 'Minutes', icon: TablerIcons.clock, iconColor: ColorTokens.info),
    StatData(value: streak.toString(), label: 'Streak', icon: TablerIcons.flame, iconColor: ColorTokens.warning),
    StatData(value: '${completion.toInt()}%', label: 'Completion', icon: TablerIcons.check, iconColor: ColorTokens.success),
  ];
});
