import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/accent_color.dart';
import 'chart_style.dart';

/// A bar chart with a label under each bar.
///
/// [values] is parallel to [labels]; a null value means "no data for that
/// bucket" and draws no bar at all, which is different from a real zero.
///
/// An optional [goal] draws a dashed reference line. When [overGoalIsBad] is
/// set, bars above it switch to the error colour — right for calories, where
/// going over is a miss, but not for a metric where more is better.
///
/// Takes labels rather than dates so the same chart serves a week of days, a
/// month of weeks and a year of months. It was previously seven-day-only and
/// lived in the calories feature; the recap charts need the same thing at three
/// different resolutions, and two near-identical charts would drift apart.
class SimpleBarChart extends ConsumerWidget {
  const SimpleBarChart({
    super.key,
    required this.labels,
    required this.values,
    required this.maxY,
    required this.yLabel,
    required this.tooltip,
    this.goal,
    this.overGoalIsBad = false,
    this.highlightLast = true,
    this.barWidth = 16,
  });

  final List<String> labels;
  final List<double?> values;

  /// Top of the y axis.
  final double maxY;

  /// Formats a y-axis tick.
  final String Function(double value) yLabel;

  /// Builds the tooltip text for the bucket at the given index.
  final String Function(int index) tooltip;

  final double? goal;
  final bool overGoalIsBad;

  /// Picks out the last bucket — "now" — in the accent colour. On by default
  /// because every chart here ends at the present.
  final bool highlightLast;

  final double barWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final interval = niceAxisInterval(maxY);

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          for (var i = 0; i < labels.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                if (values[i] != null)
                  BarChartRodData(
                    // Clamp so a huge outlier stays inside the plot area.
                    toY: values[i]!.clamp(0.0, maxY),
                    width: barWidth,
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
          getDrawingHorizontalLine: (_) => chartGridLine(context),
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
                child: Text(yLabel(value), style: chartLabelStyle(context)),
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
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                final isLast = highlightLast && i == labels.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[i],
                    style: chartLabelStyle(context)?.copyWith(
                      color: isLast ? accent : null,
                      fontWeight: isLast ? FontWeight.w700 : null,
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
double niceAxisInterval(double maxY) {
  final rough = maxY / 4;
  const steps = [
    0.1,
    0.2,
    0.25,
    0.5,
    1.0,
    2.0,
    5.0,
    10.0,
    25.0,
    50.0,
    100.0,
    250.0,
    500.0,
    1000.0,
    2500.0,
    5000.0,
    10000.0,
    25000.0,
  ];
  for (final step in steps) {
    if (step >= rough) return step;
  }
  return 50000.0;
}
