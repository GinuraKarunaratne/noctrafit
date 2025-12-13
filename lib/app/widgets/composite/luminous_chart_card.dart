import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/color_tokens.dart';

/// CW3: Luminous Chart Card - Minimal dark chart with luminous green highlights
///
/// Features:
/// - Dark background with luminous green data
/// - Uses fl_chart library
/// - NO white backgrounds (matches Image 2 vibe)
/// - Supports line and bar charts
/// - Fully customizable
///
/// Reused in: InsightsScreen, HomeScreen
class LuminousChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final ChartType chartType;
  final List<ChartDataPoint> data;
  final String? footerText;
  final VoidCallback? onTap;

  const LuminousChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.chartType,
    required this.data,
    this.footerText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorTokens.border,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: ColorTokens.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ColorTokens.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      color: ColorTokens.accent,
                      size: 16,
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Chart
              SizedBox(
                height: 180,
                child: chartType == ChartType.line
                    ? _LineChart(data: data)
                    : _BarChart(data: data),
              ),

              // Footer
              if (footerText != null) ...[
                const SizedBox(height: 12),
                Text(
                  footerText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ColorTokens.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Line chart implementation
class _LineChart extends StatelessWidget {
  final List<ChartDataPoint> data;

  const _LineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: ColorTokens.border,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const Text('');
                }
                return Text(
                  data[index].label,
                  style: const TextStyle(
                    color: ColorTokens.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: ColorTokens.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                .toList(),
            isCurved: true,
            color: ColorTokens.accent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: ColorTokens.accent,
                  strokeWidth: 2,
                  strokeColor: ColorTokens.background,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: ColorTokens.accent.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bar chart implementation
class _BarChart extends StatelessWidget {
  final List<ChartDataPoint> data;

  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: ColorTokens.border,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const Text('');
                }
                return Text(
                  data[index].label,
                  style: const TextStyle(
                    color: ColorTokens.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: ColorTokens.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data
            .asMap()
            .entries
            .map(
              (e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.value,
                    color: ColorTokens.accent,
                    width: 16,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Chart data point model
class ChartDataPoint {
  final double value;
  final String label;

  const ChartDataPoint({
    required this.value,
    required this.label,
  });
}

/// Chart type enum
enum ChartType {
  line,
  bar,
}
