import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/exercise_display.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/bar_chart.dart';
import '../../../shared/widgets/chart_style.dart';
import '../../muscle_map/data/muscle_colors.dart';
import '../../home/data/recap.dart';
import '../../home/data/recap_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_segmented.dart';

/// The Home tab's recap: how much, how often, what, and how many records.
///
/// One period selector drives all four cards. They answer different questions
/// about the same stretch of time, so switching them independently would only
/// invite comparing a week of volume against a year of sessions.
class RecapSection extends ConsumerStatefulWidget {
  const RecapSection({super.key});

  @override
  ConsumerState<RecapSection> createState() => _RecapSectionState();
}

class _RecapSectionState extends ConsumerState<RecapSection> {
  RecapPeriod _period = RecapPeriod.week;

  @override
  Widget build(BuildContext context) {
    final recap = ref.watch(recapProvider(_period));
    final unit = ref.watch(weightUnitProvider);

    // Nothing logged in any period yet — the Home tab already tells a new user
    // what to do, and four empty charts underneath would just be furniture.
    if (recap == null || (recap.isEmpty && _period == RecapPeriod.week)) {
      final hasAnything =
          ref.watch(recapSetsProvider).value?.isNotEmpty ?? false;
      if (!hasAnything) return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The range, full width and on its own line. It used to be a
        // SegmentedButton squeezed beside a "Recap" heading, which left it
        // about a third of the width for three labels — and the heading was
        // naming the screen you were already looking at.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: AppSegmented<RecapPeriod>(
            selected: _period,
            onChanged: (value) => setState(() => _period = value),
            segments: [
              for (final period in RecapPeriod.values)
                (value: period, label: period.label, leading: null),
            ],
          ),
        ),
        if (recap == null)
          const SizedBox(height: 120)
        else if (recap.isEmpty)
          _EmptyPeriod(period: _period)
        else ...[
          _VolumeCard(recap: recap, unit: unit),
          _SessionsCard(recap: recap),
          _MusclesCard(recap: recap),
        ],
      ],
    );
  }
}

/// A period with no training in it. Says which period, because the fix is
/// usually "look at a longer one" rather than "go to the gym".
class _EmptyPeriod extends StatelessWidget {
  const _EmptyPeriod({required this.period});

  final RecapPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'Nothing logged in the last ${period.label.toLowerCase()}.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _RecapCard extends StatelessWidget {
  const _RecapCard({
    required this.title,
    required this.headline,
    required this.detail,
    required this.child,
  });

  final String title;
  final String headline;
  final String detail;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(headline, style: theme.textTheme.headlineSmall),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _VolumeCard extends StatelessWidget {
  const _VolumeCard({required this.recap, required this.unit});

  final RecapSummary recap;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final values = [
      for (final b in recap.buckets)
        // Zero draws no bar rather than a flat line on the axis: a rest day and
        // a day you trained nothing into are the same thing, and neither is a
        // data point worth drawing.
        b.volumeKg == 0 ? null : weightIn(b.volumeKg, unit),
    ];
    final peak = values.whereType<double>().fold<double>(
      0,
      (m, v) => v > m ? v : m,
    );

    return _RecapCard(
      title: 'Volume',
      headline: formatWeightUnit(recap.totalVolumeKg, unit),
      detail: 'lifted in the last ${recap.period.label.toLowerCase()}',
      // A line, not bars. Volume over time is a *trend* — the question is
      // whether it is going up — and a row of bars asks you to compare their
      // heights to answer that. The sessions card below stays bars, because
      // "how many workouts in week three" is a quantity, not a direction.
      child: SizedBox(
        height: 150,
        child: _VolumeLine(
          values: values,
          labels: [for (final b in recap.buckets) b.label],
          peak: peak,
        ),
      ),
    );
  }
}

/// Volume across the period, as a line with the area under it filled.
class _VolumeLine extends ConsumerWidget {
  const _VolumeLine({
    required this.values,
    required this.labels,
    required this.peak,
  });

  /// Null where nothing was logged — a rest day is not a zero, it is an absence.
  final List<double?> values;
  final List<String> labels;
  final double peak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++)
        if (values[i] != null) FlSpot(i.toDouble(), values[i]!),
    ];

    if (spots.length < 2) {
      return Center(
        child: Text(
          'One day is not a trend yet.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: 0,
        // Headroom so the peak is not drawn along the top edge of the card.
        maxY: peak == 0 ? 1 : peak * 1.12,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => chartGridLine(context),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(labels[index], style: chartLabelStyle(context)),
                );
              },
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: accent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            // Dots only while there are few enough to read; past a dozen they
            // become a dotted line rather than marks you can pick out.
            dotData: FlDotData(show: chartShowsDots(spots.length)),
            belowBarData: chartAreaFill(accent),
          ),
        ],
      ),
    );
  }
}

class _SessionsCard extends StatelessWidget {
  const _SessionsCard({required this.recap});

  final RecapSummary recap;

  @override
  Widget build(BuildContext context) {
    final peak = recap.buckets.fold<int>(
      0,
      (m, b) => b.sessions > m ? b.sessions : m,
    );

    return _RecapCard(
      title: 'Workouts',
      headline: '${recap.sessions}',
      detail: recap.personalRecords == 0
          ? 'sessions in the last ${recap.period.label.toLowerCase()}'
          : 'sessions • ${recap.personalRecords} personal '
                '${recap.personalRecords == 1 ? 'record' : 'records'}',
      child: SizedBox(
        height: 140,
        child: SimpleBarChart(
          labels: [for (final b in recap.buckets) b.label],
          values: [
            for (final b in recap.buckets)
              b.sessions == 0 ? null : b.sessions.toDouble(),
          ],
          // At least 1 so a single-workout period doesn't draw a full-height
          // bar and read as a big number.
          maxY: (peak == 0 ? 1 : peak) + 1,
          yLabel: (value) =>
              value == value.roundToDouble() ? '${value.round()}' : '',
          tooltip: (i) =>
              '${recap.buckets[i].sessions} '
              '${recap.buckets[i].sessions == 1 ? 'workout' : 'workouts'}',
        ),
      ),
    );
  }
}

/// Sets per muscle, most first, as proportional bars.
///
/// Sets, not volume: a set of squats moves five times the weight of a set of
/// curls, so ranking by kilograms would put legs at the top of every chart
/// regardless of how the week actually went. Counting sets measures attention
/// rather than load, which is the question this card is asking.
///
/// A bar list rather than a pie: comparing lengths against a common baseline is
/// easier than comparing wedge angles, and the interesting question here is
/// "which one got the least", which a pie hides.
class _MusclesCard extends ConsumerWidget {
  const _MusclesCard({required this.recap});

  final RecapSummary recap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entries = recap.muscleSets.entries.toList()
      // Ties broken by name so the order is stable between rebuilds rather
      // than shuffling whenever two muscles have the same count.
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    if (entries.isEmpty) return const SizedBox.shrink();

    // The top eight. Past that the bars are slivers and the card is a wall of
    // text; the tail is always incidental muscles picked up by compounds.
    final shown = entries.take(8).toList();
    final top = shown.first.value;

    return _RecapCard(
      title: 'What you trained',
      headline: muscleLabel(shown.first.key),
      detail: 'took the most sets',
      child: Column(
        children: [
          for (final entry in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      muscleLabel(entry.key),
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: top == 0 ? 0 : entry.value / top,
                        minHeight: 8,
                        // The muscle map's own colours, so the two screens
                        // agree about which colour means which muscle.
                        color: muscleColor(entry.key),
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 52,
                    child: Text(
                      '${entry.value} ${entry.value == 1 ? 'set' : 'sets'}',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Volume axis labels get long fast — 12,000 kg in a week is ordinary. `12k`
