import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';

import '../../../app/theme/color_tokens.dart';
import '../../../app/widgets/composite/stats_grid.dart';
import '../widgets/adaptive_banner_card.dart';

/// Home screen - Main dashboard with time-aware banner and stats
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Load real stats from insights repository
    final weeklyStats = _getMockWeeklyStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NoctraFit'),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.bell),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CW1: Time-aware adaptive banner
            AdaptiveBannerCard.timeAware(
              onTap: () {
                // TODO: Navigate to suggested workout
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Starting suggested workout...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              onDismiss: () {
                // TODO: Save dismissal preference
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Banner dismissed'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // Section: Weekly Overview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'This Week',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ColorTokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            // CW2: Stats Grid
            StatsGrid(stats: weeklyStats),

            const SizedBox(height: 16),

            // Section: Trending Workouts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trending Workouts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: ColorTokens.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to plans screen
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Trending workout cards (placeholder)
            _TrendingWorkoutsList(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<StatData> _getMockWeeklyStats() {
    // TODO: Replace with real data from InsightsRepository
    return [
      const StatData(
        value: '4',
        label: 'Workouts',
        icon: TablerIcons.barbell,
        trend: TrendData(
          direction: TrendDirection.up,
          value: '+2',
          isPositive: true,
        ),
      ),
      const StatData(
        value: '127',
        label: 'Minutes',
        icon: TablerIcons.clock,
        trend: TrendData(
          direction: TrendDirection.up,
          value: '+15%',
          isPositive: true,
        ),
      ),
      const StatData(
        value: '3',
        label: 'Streak',
        icon: TablerIcons.flame,
        iconColor: ColorTokens.warning,
        trend: TrendData(
          direction: TrendDirection.neutral,
        ),
      ),
      const StatData(
        value: '87%',
        label: 'Completion',
        icon: TablerIcons.chart_pie,
        iconColor: ColorTokens.success,
        trend: TrendData(
          direction: TrendDirection.up,
          value: '+5%',
          isPositive: true,
        ),
      ),
    ];
  }
}

/// Trending workouts list (placeholder)
class _TrendingWorkoutsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Load from SetsRepository with sort by popularity
    final mockWorkouts = [
      {'name': 'Night Shift Quick Starter', 'duration': '15 min', 'difficulty': 'Beginner'},
      {'name': 'Midnight Full Body Burn', 'duration': '30 min', 'difficulty': 'Intermediate'},
      {'name': 'Night Owl HIIT', 'duration': '25 min', 'difficulty': 'Advanced'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: mockWorkouts.length,
      itemBuilder: (context, index) {
        final workout = mockWorkouts[index];
        return _WorkoutCard(
          name: workout['name']!,
          duration: workout['duration']!,
          difficulty: workout['difficulty']!,
          onTap: () {
            // TODO: Navigate to workout details
          },
        );
      },
    );
  }
}

/// Individual workout card
class _WorkoutCard extends StatelessWidget {
  final String name;
  final String duration;
  final String difficulty;
  final VoidCallback onTap;

  const _WorkoutCard({
    required this.name,
    required this.duration,
    required this.difficulty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorTokens.border,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorTokens.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  TablerIcons.barbell,
                  color: ColorTokens.accent,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: ColorTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          TablerIcons.clock,
                          size: 12,
                          color: ColorTokens.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ColorTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(difficulty).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            difficulty,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getDifficultyColor(difficulty),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                TablerIcons.chevron_right,
                color: ColorTokens.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return ColorTokens.success;
      case 'intermediate':
        return ColorTokens.warning;
      case 'advanced':
        return ColorTokens.error;
      default:
        return ColorTokens.textSecondary;
    }
  }
}
