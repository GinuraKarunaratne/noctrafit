import 'package:flutter/material.dart';
import '../../theme/color_tokens.dart';

/// CW2: Stats Grid - Reusable grid of stat cards
///
/// Features:
/// - Flexible grid layout (2-4 columns based on screen width)
/// - Icon + value + label + optional trend indicator
/// - Themeable with ColorTokens
/// - Accepts generic StatData
///
/// Reused in: HomeScreen, ProfileScreen
class StatsGrid extends StatelessWidget {
  final List<StatData> stats;
  final int crossAxisCount;
  final double spacing;

  const StatsGrid({
    super.key,
    required this.stats,
    this.crossAxisCount = 2,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.3,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return _StatCard(stat: stats[index]);
      },
    );
  }
}

/// Individual stat card
class _StatCard extends StatelessWidget {
  final StatData stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorTokens.border,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and optional trend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                stat.icon,
                color: stat.iconColor ?? ColorTokens.accent,
                size: 24,
              ),
              if (stat.trend != null) _TrendIndicator(trend: stat.trend!),
            ],
          ),

          const SizedBox(height: 12),

          // Value
          Text(
            stat.value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: ColorTokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Label
          Text(
            stat.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: ColorTokens.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Trend indicator (up/down/neutral)
class _TrendIndicator extends StatelessWidget {
  final TrendData trend;

  const _TrendIndicator({required this.trend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;

    switch (trend.direction) {
      case TrendDirection.up:
        icon = Icons.trending_up;
        color = trend.isPositive ? ColorTokens.success : ColorTokens.error;
        break;
      case TrendDirection.down:
        icon = Icons.trending_down;
        color = trend.isPositive ? ColorTokens.success : ColorTokens.error;
        break;
      case TrendDirection.neutral:
        icon = Icons.trending_flat;
        color = ColorTokens.textSecondary;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trend.value != null)
          Text(
            trend.value!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(width: 2),
        Icon(
          icon,
          color: color,
          size: 16,
        ),
      ],
    );
  }
}

/// Data model for a single stat
class StatData {
  final String value;
  final String label;
  final IconData icon;
  final Color? iconColor;
  final TrendData? trend;

  const StatData({
    required this.value,
    required this.label,
    required this.icon,
    this.iconColor,
    this.trend,
  });
}

/// Data model for trend indicator
class TrendData {
  final TrendDirection direction;
  final String? value; // e.g., "+5%", "-2"
  final bool isPositive; // Is this trend good or bad?

  const TrendData({
    required this.direction,
    this.value,
    this.isPositive = true,
  });

  // Factory helpers
  static TrendData up(String? value, {bool isPositive = true}) {
    return TrendData(
      direction: TrendDirection.up,
      value: value,
      isPositive: isPositive,
    );
  }

  static TrendData down(String? value, {bool isPositive = false}) {
    return TrendData(
      direction: TrendDirection.down,
      value: value,
      isPositive: isPositive,
    );
  }

  static TrendData neutral() {
    return const TrendData(direction: TrendDirection.neutral);
  }
}

/// Trend direction enum
enum TrendDirection {
  up,
  down,
  neutral,
}
