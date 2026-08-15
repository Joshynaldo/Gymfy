import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/format.dart';

/// A seven-day bar chart with weekday labels along the bottom.
///
/// Shared by the weekly overview's calorie and habit charts so both read the
/// same. [values] is parallel to [days]; a null value means "no data for that
/// day" and draws no bar at all (different from a real zero).
///
/// An optional [goal] draws a dashed reference line. When [overGoalIsBad] is
/// set, bars above it switch to the error colour — right for calories (going
/// over is a miss) but not for habit completion.
class WeeklyBarChart extends ConsumerWidget {
  const WeeklyBarChart({
    super.key,
    required this.days,
    required this.values,
    required this.maxY,
    required this.yLabel,
    required this.tooltip,
    this.goal,
    this.overGoalIsBad = false,
  });

  final List<DateTime> days;
  final List<double?> values;

  /// Top of the y axis.
  final double maxY;

  /// Formats a y-axis tick.
  final String Function(double value) yLabel;

  /// Builds the tooltip text for the day at the given index.
  final String Function(int index) tooltip;

  final double? goal;
  final bool overGoalIsBad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final interval = _niceInterval(maxY);

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                if (values[i] != null)
                  BarChartRodData(
                    // Clamp so a huge outlier stays inside the plot area.
                    toY: values[i]!.clamp(0.0, maxY),
                    width: 16,
                    color: overGoalIsBad && goal != null && values[i]! > goal!
                        ? theme.colorScheme.error
                        : accent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
              ],
            ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (goal != null && goal! <= maxY)
              HorizontalLine(
                y: goal!,
                color: theme.colorScheme.onSurfaceVariant,
                strokeWidth: 1,
                dashArray: const [6, 4],
              ),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: interval,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(yLabel(value), style: theme.textTheme.bodySmall),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, _) {
                final i = value.round();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                final isToday = i == days.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    formatWeekdayAbbr(days[i]),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isToday ? accent : null,
                      fontWeight: isToday ? FontWeight.w700 : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItem: (group, _, _, _) => BarTooltipItem(
              tooltip(group.x),
              TextStyle(
                color: theme.colorScheme.onInverseSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Picks a tidy y-axis gridline interval so there are roughly four lines.
double _niceInterval(double maxY) {
  final rough = maxY / 4;
  const steps = [
    0.1, 0.2, 0.25, 0.5, 1.0, 2.0, 5.0, 10.0, 25.0, 50.0,
    100.0, 250.0, 500.0, 1000.0,
  ];
  for (final step in steps) {
    if (step >= rough) return step;
  }
  return 1000.0;
}
