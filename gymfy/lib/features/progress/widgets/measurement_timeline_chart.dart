import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/format.dart';
import '../data/measurements_repository.dart';

/// The y-axis window for a measurement series: a padded band around the actual
/// values.
///
/// Measurements move in a narrow range (82–84 kg over a month), so anchoring the
/// axis at zero would squash every change into a flat line. Instead the axis
/// hugs the data with a little headroom.
({double min, double max}) axisRange(List<double> values) {
  final lowest = values.reduce((a, b) => a < b ? a : b);
  final highest = values.reduce((a, b) => a > b ? a : b);
  // A flat series still needs a band, hence the minimum padding.
  final padding = ((highest - lowest) * 0.2).clamp(0.5, double.infinity);
  final min = lowest - padding;
  return (min: min < 0 ? 0 : min, max: highest + padding);
}

/// A line chart of one body measurement over time.
///
/// X is real elapsed days from the first measurement, not the point index, so a
/// three-week gap looks like a three-week gap.
class MeasurementTimelineChart extends ConsumerWidget {
  const MeasurementTimelineChart({
    super.key,
    required this.points,
    required this.unit,
  });

  /// Oldest first, as [seriesFor] returns. Must hold at least two points.
  final List<MeasurementPoint> points;

  /// Unit for tooltips and axis labels, e.g. "kg".
  final String unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    final first = points.first.day;
    double dayOffset(DateTime day) => day.difference(first).inDays.toDouble();

    final spots = [
      for (final point in points) FlSpot(dayOffset(point.day), point.value),
    ];
    final range = axisRange([for (final point in points) point.value]);
    final maxX = spots.last.x;
    final yInterval = _niceInterval(range.max - range.min);

    final gridLine = FlLine(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
      strokeWidth: 1,
    );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: range.min,
        maxY: range.max,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => gridLine,
        ),
        borderData: FlBorderData(show: false),
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
              interval: yInterval,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  formatWeight(value),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              // Roughly four date labels, whatever the span.
              interval: (maxX / 4).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                // Skip the label that would collide with the axis edge.
                if (value > maxX) return const SizedBox.shrink();
                final day = first.add(Duration(days: value.round()));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    formatShortDate(day),
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final day = first.add(Duration(days: spot.x.round()));
              return LineTooltipItem(
                '${formatWeight(spot.y)} $unit\n${formatShortDate(day)}',
                TextStyle(
                  color: theme.colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: accent,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: 4,
                color: accent,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: accent.withValues(alpha: 0.15),
              // Fill down to the bottom of the visible band, not to zero.
              cutOffY: range.min,
              applyCutOffY: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Picks a tidy y-axis gridline interval so there are roughly four lines.
double _niceInterval(double span) {
  final rough = span / 4;
  const steps = [0.5, 1.0, 2.0, 2.5, 5.0, 10.0, 20.0, 25.0, 50.0];
  for (final step in steps) {
    if (step >= rough) return step;
  }
  return 100.0;
}
