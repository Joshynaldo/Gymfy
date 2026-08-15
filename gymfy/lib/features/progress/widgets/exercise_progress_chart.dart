import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/format.dart';
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

    // Plotted in the display unit rather than in kilograms, so the gridlines
    // and axis labels land on round numbers in whichever unit is on screen —
    // converting only the labels would give ticks like 110, 220, 331.
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), weightIn(points[i].topWeight, unit)),
    ];

    final maxWeight = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    // Round the top of the axis up to something tidy and leave headroom.
    final maxY = maxWeight <= 0 ? 10.0 : (maxWeight * 1.2);
    final yInterval = _niceInterval(maxY);

    // Show at most ~6 date labels so the axis doesn't get crowded.
    final labelStep = (points.length / 6).ceil().clamp(1, points.length);

    final gridLine = FlLine(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
      strokeWidth: 1,
    );

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
              reservedSize: 40,
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
              final p = points[spot.x.round()];
              return LineTooltipItem(
                '${formatWeightUnit(p.topWeight, unit)} × ${p.repsAtTop}\n'
                '${formatShortDate(p.date)}',
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
            ),
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
