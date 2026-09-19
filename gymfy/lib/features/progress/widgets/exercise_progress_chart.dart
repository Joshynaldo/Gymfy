import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/chart_style.dart';
import '../../../shared/utils/units.dart';
import '../data/progress_repository.dart';

/// A line chart of an exercise's top-set weight across sessions over time.
///
/// X is the session (oldest → newest) with dated labels; Y is weight in the
/// user's chosen unit.
/// The line and dots use the app accent colour.
class ExerciseProgressChart extends ConsumerWidget {
  const ExerciseProgressChart({super.key, required this.points});

  final List<ExerciseHistoryPoint> points;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final unit = ref.watch(weightUnitProvider);

    // An exercise logged by time is charted by time. Plotting its weight
    // would draw a flat line along zero and call it progress — the numbers
    // are there, they are just seconds.
    //
    // Decided per *series* rather than per point, from whether any session
    // was a hold: an exercise does not change kind halfway through, and a
    // chart that switched axis mid-line would be unreadable.
    final holds = points.any((p) => p.isHold);

    // Plotted in the display unit rather than in kilograms, so the gridlines
    // and axis labels land on round numbers in whichever unit is on screen —
    // converting only the labels would give ticks like 110, 220, 331.
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(
          i.toDouble(),
          holds
              ? (points[i].longestHold ?? 0).toDouble()
              : weightIn(points[i].topWeight, unit),
        ),
    ];

    final maxWeight = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    // Round the top of the axis up to something tidy and leave headroom.
    final maxY = maxWeight <= 0 ? 10.0 : (maxWeight * 1.2);
    final yInterval = _niceInterval(maxY);

    // Show at most ~6 date labels so the axis doesn't get crowded.
    final labelStep = (points.length / 6).ceil().clamp(1, points.length);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble().clamp(0, double.infinity),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => chartGridLine(context),
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
              reservedSize: 40,
              interval: yInterval,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  // Seconds read as a clock on the axis too, so "90" never
                  // sits there ambiguously between a weight and a duration.
                  holds
                      ? formatSetDuration(value.round())
                      : formatWeight(value),
                  style: chartLabelStyle(context),
                ),
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
                if (i < 0 || i >= points.length) {
                  return const SizedBox.shrink();
                }
                if (i % labelStep != 0 && i != points.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    formatShortDate(points[i].date),
                    style: chartLabelStyle(context),
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
              final p = points[spot.x.round()];
              final headline = holds
                  ? formatSetDuration(p.longestHold ?? 0)
                  : '${formatWeightUnit(p.topWeight, unit)} × ${p.repsAtTop}';
              return LineTooltipItem(
                '$headline\n${formatShortDate(p.date)}',
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
              // Only while you can still count them — see chartShowsDots.
              show: chartShowsDots(spots.length),
              getDotPainter: (spot, _, _, _) =>
                  FlDotCirclePainter(radius: 4, color: accent, strokeWidth: 0),
            ),
            belowBarData: chartAreaFill(accent),
          ),
        ],
      ),
    );
  }
}

/// Picks a tidy y-axis gridline interval so there are roughly four lines.
double _niceInterval(double maxY) {
  final rough = maxY / 4;
  const steps = [1.0, 2.0, 2.5, 5.0, 10.0, 20.0, 25.0, 50.0, 100.0];
  for (final step in steps) {
    if (step >= rough) return step;
  }
  return 100.0;
}
