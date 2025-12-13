import 'package:flutter/material.dart';
import '../../../app/theme/color_tokens.dart';

/// CW4: Progress Heatmap Card - GitHub-style contribution grid
///
/// Features:
/// - 365 days, 7 rows (weekdays), scrollable horizontally
/// - 5 intensity levels (0=surface, 4=full accent)
/// - Legend: "Less" → boxes → "More"
/// - Matches Image 4 exactly
///
/// Reused in: ProfileScreen, InsightsScreen
class ProgressHeatmapCard extends StatelessWidget {
  final String title;
  final Map<DateTime, int> completionsByDate; // Date → workout count
  final int maxIntensity;
  final VoidCallback? onTap;

  const ProgressHeatmapCard({
    super.key,
    required this.title,
    required this.completionsByDate,
    this.maxIntensity = 3,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorTokens.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: ColorTokens.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onTap != null)
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 18),
                    color: ColorTokens.textSecondary,
                    onPressed: onTap,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Heatmap grid
            _HeatmapGrid(
              completionsByDate: completionsByDate,
              maxIntensity: maxIntensity,
            ),

            const SizedBox(height: 16),

            // Legend
            _HeatmapLegend(maxIntensity: maxIntensity),
          ],
        ),
      ),
    );
  }
}

/// Heatmap grid widget (365 days)
class _HeatmapGrid extends StatelessWidget {
  final Map<DateTime, int> completionsByDate;
  final int maxIntensity;

  const _HeatmapGrid({
    required this.completionsByDate,
    required this.maxIntensity,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate weeks to display (52 weeks = ~1 year)
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 364));

    // Group days by week
    final weeks = <List<DateTime>>[];
    var currentWeek = <DateTime>[];
    var currentDate = _normalizeDate(startDate);

    // Start from the beginning of the week (Sunday)
    final firstDayOfWeek = currentDate.weekday % 7;
    currentDate = currentDate.subtract(Duration(days: firstDayOfWeek));

    for (int i = 0; i < 371; i++) {
      currentWeek.add(currentDate);
      if (currentWeek.length == 7) {
        weeks.add(List.from(currentWeek));
        currentWeek.clear();
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return SizedBox(
      height: 120,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: weeks.map((week) {
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                children: week.map((date) {
                  return _HeatmapCell(
                    date: date,
                    count: _getCountForDate(date),
                    maxIntensity: maxIntensity,
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  int _getCountForDate(DateTime date) {
    final normalized = _normalizeDate(date);
    return completionsByDate[normalized] ?? 0;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

/// Individual heatmap cell
class _HeatmapCell extends StatelessWidget {
  final DateTime date;
  final int count;
  final int maxIntensity;

  const _HeatmapCell({
    required this.date,
    required this.count,
    required this.maxIntensity,
  });

  @override
  Widget build(BuildContext context) {
    final intensity = _calculateIntensity();
    final color = _getColorForIntensity(intensity);

    return Tooltip(
      message: '${date.month}/${date.day}: $count workouts',
      child: Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: intensity == 0 ? ColorTokens.border : color.darken(10),
            width: 0.5,
          ),
        ),
      ),
    );
  }

  int _calculateIntensity() {
    if (count == 0) return 0;
    if (count >= maxIntensity) return 4;

    // Map count to intensity levels 1-4
    final ratio = count / maxIntensity;
    if (ratio < 0.25) return 1;
    if (ratio < 0.5) return 2;
    if (ratio < 0.75) return 3;
    return 4;
  }

  Color _getColorForIntensity(int intensity) {
    switch (intensity) {
      case 0:
        return ColorTokens.surface.lighten(5); // No activity
      case 1:
        return ColorTokens.accent.withOpacity(0.2);
      case 2:
        return ColorTokens.accent.withOpacity(0.4);
      case 3:
        return ColorTokens.accent.withOpacity(0.7);
      case 4:
        return ColorTokens.accent; // Full intensity
      default:
        return ColorTokens.surface;
    }
  }
}

/// Heatmap legend
class _HeatmapLegend extends StatelessWidget {
  final int maxIntensity;

  const _HeatmapLegend({required this.maxIntensity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Less',
          style: theme.textTheme.bodySmall?.copyWith(
            color: ColorTokens.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          return Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _getColorForLevel(index),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: index == 0
                    ? ColorTokens.border
                    : _getColorForLevel(index).darken(10),
                width: 0.5,
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          'More',
          style: theme.textTheme.bodySmall?.copyWith(
            color: ColorTokens.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getColorForLevel(int level) {
    switch (level) {
      case 0:
        return ColorTokens.surface.lighten(5);
      case 1:
        return ColorTokens.accent.withOpacity(0.2);
      case 2:
        return ColorTokens.accent.withOpacity(0.4);
      case 3:
        return ColorTokens.accent.withOpacity(0.7);
      case 4:
        return ColorTokens.accent;
      default:
        return ColorTokens.surface;
    }
  }
}
