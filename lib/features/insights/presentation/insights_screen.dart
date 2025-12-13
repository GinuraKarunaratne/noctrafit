import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';

import '../../../app/theme/color_tokens.dart';
import '../../../app/widgets/composite/luminous_chart_card.dart';
import '../../../app/widgets/composite/stats_grid.dart';

/// Insights screen - Stats, charts, and analytics
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // TODO: Load real data from InsightsRepository
    final weeklyData = _getWeeklyChartData();
    final monthlyData = _getMonthlyChartData();
    final monthlyStats = _getMonthlyStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.calendar_stats),
            onPressed: () {
              // TODO: Show date range picker
            },
          ),
        ],
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

            StatsGrid(
              stats: monthlyStats,
              crossAxisCount: 2,
            ),

            const SizedBox(height: 16),

            // CW3: Weekly workout frequency chart
            LuminousChartCard(
              title: 'Weekly Workouts',
              subtitle: 'Last 7 days',
              chartType: ChartType.bar,
              data: weeklyData,
              footerText: 'Avg 2.3 workouts per day',
            ),

            // CW3: Monthly minutes chart
            LuminousChartCard(
              title: 'Monthly Activity',
              subtitle: 'Last 30 days',
              chartType: ChartType.line,
              data: monthlyData,
              footerText: 'Total: 847 minutes this month',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('View detailed breakdown')),
                );
              },
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

            _CategoryBreakdown(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<StatData> _getMonthlyStats() {
    return const [
      StatData(
        value: '18',
        label: 'Workouts',
        icon: TablerIcons.barbell,
        trend: TrendData(
          direction: TrendDirection.up,
          value: '+6',
          isPositive: true,
        ),
      ),
      StatData(
        value: '847',
        label: 'Minutes',
        icon: TablerIcons.clock,
        trend: TrendData(
          direction: TrendDirection.up,
          value: '+120',
          isPositive: true,
        ),
      ),
      StatData(
        value: '12',
        label: 'Streak',
        icon: TablerIcons.flame,
        iconColor: ColorTokens.warning,
        trend: TrendData(
          direction: TrendDirection.up,
          value: '+3',
          isPositive: true,
        ),
      ),
      StatData(
        value: '94%',
        label: 'Completion',
        icon: TablerIcons.chart_pie,
        iconColor: ColorTokens.success,
        trend: TrendData(
          direction: TrendDirection.up,
          value: '+7%',
          isPositive: true,
        ),
      ),
    ];
  }

  List<ChartDataPoint> _getWeeklyChartData() {
    // TODO: Load from CompletionLogsDao
    return const [
      ChartDataPoint(value: 1, label: 'Mon'),
      ChartDataPoint(value: 2, label: 'Tue'),
      ChartDataPoint(value: 1, label: 'Wed'),
      ChartDataPoint(value: 3, label: 'Thu'),
      ChartDataPoint(value: 2, label: 'Fri'),
      ChartDataPoint(value: 1, label: 'Sat'),
      ChartDataPoint(value: 2, label: 'Sun'),
    ];
  }

  List<ChartDataPoint> _getMonthlyChartData() {
    // TODO: Load from CompletionLogsDao
    return const [
      ChartDataPoint(value: 120, label: 'W1'),
      ChartDataPoint(value: 180, label: 'W2'),
      ChartDataPoint(value: 210, label: 'W3'),
      ChartDataPoint(value: 337, label: 'W4'),
    ];
  }
}

/// Category breakdown widget
class _CategoryBreakdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Cardio', 'workouts': 8, 'percentage': 44, 'icon': TablerIcons.run},
      {'name': 'Strength', 'workouts': 7, 'percentage': 39, 'icon': TablerIcons.barbell},
      {'name': 'Flexibility', 'workouts': 3, 'percentage': 17, 'icon': TablerIcons.yoga},
    ];

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
