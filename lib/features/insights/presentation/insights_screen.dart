import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/color_tokens.dart';
import '../../../app/widgets/composite/luminous_chart_card.dart';
import '../../../app/widgets/composite/stats_grid.dart';
import '../providers/insights_providers.dart';

/// Insights screen - Stats, charts, and analytics
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Load real data from providers
    final monthlyStatsAsync = ref.watch(monthlyStatsProvider);
    final weeklyDataAsync = ref.watch(weeklyChartDataProvider);
    final monthlyDataAsync = ref.watch(monthlyChartDataProvider);
    final monthlyMinutesAsync = ref.watch(monthlyMinutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Monthly stats overview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'This Month',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: ColorTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            monthlyStatsAsync.when(
              data: (stats) => StatsGrid(stats: stats, crossAxisCount: 2),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // Weekly workout frequency chart
            weeklyDataAsync.when(
              data: (data) => LuminousChartCard(
                title: 'Weekly Workouts',
                subtitle: 'Last 7 days',
                chartType: ChartType.bar,
                data: data,
                footerText: 'Track your daily consistency',
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Monthly minutes chart
            monthlyDataAsync.when(
              data: (data) => monthlyMinutesAsync.when(
                data: (totalMinutes) => LuminousChartCard(
                  title: 'Monthly Activity',
                  subtitle: 'Last 4 weeks',
                  chartType: ChartType.line,
                  data: data,
                  footerText: 'Total: $totalMinutes minutes this month',
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // Category breakdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Category Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: ColorTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            const _CategoryBreakdown(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Category breakdown widget
class _CategoryBreakdown extends ConsumerWidget {
  const _CategoryBreakdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryBreakdownAsync = ref.watch(categoryBreakdownProvider);

    return categoryBreakdownAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No workout data yet',
                style: TextStyle(color: ColorTokens.textSecondary),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryCard(
              name: category['name']! as String,
              workouts: category['workouts']! as int,
              percentage: category['percentage']! as int,
              icon: category['icon']! as IconData,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Category card widget
class _CategoryCard extends StatelessWidget {
  final String name;
  final int workouts;
  final int percentage;
  final IconData icon;

  const _CategoryCard({
    required this.name,
    required this.workouts,
    required this.percentage,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorTokens.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: ColorTokens.accent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: ColorTokens.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$workouts workouts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ColorTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$percentage%',
            style: theme.textTheme.titleMedium?.copyWith(
              color: ColorTokens.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
