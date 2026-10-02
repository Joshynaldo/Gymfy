import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/accent_color.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/models/body_measurement.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/app_chip.dart';
import '../data/measurement_units.dart';
import '../data/measurements_repository.dart';
import '../widgets/measurement_timeline_chart.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';

/// A timeline of one body measurement, with a picker to switch body part.
class MeasurementHistoryScreen extends ConsumerStatefulWidget {
  const MeasurementHistoryScreen({super.key});

  @override
  ConsumerState<MeasurementHistoryScreen> createState() =>
      _MeasurementHistoryScreenState();
}

class _MeasurementHistoryScreenState
    extends ConsumerState<MeasurementHistoryScreen> {
  MeasurementField _field = MeasurementField.weight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final historyAsync = ref.watch(measurementHistoryProvider);

    return GlassScaffold(
      appBar: GlassAppBar(title: Text(l10n.progressHistoryTitle)),
      body: (context) => historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.progressMeasurementsLoadFailed('$error'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (rows) => _Body(
          rows: rows,
          field: _field,
          onFieldChanged: (field) => setState(() => _field = field),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.rows,
    required this.field,
    required this.onFieldChanged,
  });

  final List<BodyMeasurement> rows;
  final MeasurementField field;
  final ValueChanged<MeasurementField> onFieldChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(weightUnitProvider);
    final points = seriesFor(rows, field);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24) + barInsets(context),
      children: [
        _FieldPicker(selected: field, onChanged: onFieldChanged),
        const SizedBox(height: 16),
        if (points.length < 2)
          _NotEnoughData(field: field, points: points)
        else ...[
          _Summary(field: field, points: points),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: MeasurementTimelineChart(
              // Converted here rather than inside the chart, so the chart's
              // axis padding and gridlines are computed on what's displayed.
              points: [
                for (final point in points)
                  (
                    day: point.day,
                    value: field.displayValue(point.value, unit),
                  ),
              ],
              unit: field.labelIn(unit),
            ),
          ),
        ],
      ],
    );
  }
}

class _FieldPicker extends ConsumerWidget {
  const _FieldPicker({required this.selected, required this.onChanged});

  final MeasurementField selected;
  final ValueChanged<MeasurementField> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final field in MeasurementField.values)
          AppChip(
            label: field.localizedLabel(context.l10n),
            selected: field == selected,
            onTap: () => onChanged(field),
          ),
      ],
    );
  }
}

/// Headline numbers above the chart: where you are now and how far you've moved.
class _Summary extends ConsumerWidget {
  const _Summary({required this.field, required this.points});

  final MeasurementField field;
  final List<MeasurementPoint> points;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = ref.watch(accentColorProvider);
    final unit = ref.watch(weightUnitProvider);

    final latest = points.last;
    // In display units, so the change agrees with the figure beside it.
    final change =
        field.displayValue(latest.value, unit) -
        field.displayValue(points.first.value, unit);
    final days = latest.day.difference(points.first.day).inDays;
    final sign = change > 0 ? '+' : (change < 0 ? '−' : '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                field.formatValue(latest.value, unit, l10n: l10n),
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(width: 4),
              Text(field.labelIn(unit), style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                // Direction only, no colour coding — see _FieldTile.
                '$sign${formatWeight(change.abs(), l10n: l10n)} '
                '${field.labelIn(unit)}',
                style: theme.textTheme.titleMedium?.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.progressHistoryCount(points.length, days),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotEnoughData extends ConsumerWidget {
  const _NotEnoughData({required this.field, required this.points});

  final MeasurementField field;
  final List<MeasurementPoint> points;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final unit = ref.watch(weightUnitProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(
            LucideIcons.chartLine,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            points.isEmpty
                ? l10n.progressHistoryNone(field.name)
                : l10n.progressHistoryOnlyOne(field.name),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            points.isEmpty
                ? l10n.progressHistoryNoneHint(field.name)
                : l10n.progressHistoryOnlyOneHint(
                    field.formatWithUnit(points.single.value, unit, l10n: l10n),
                    formatShortDate(points.single.day, l10n: l10n),
                  ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
