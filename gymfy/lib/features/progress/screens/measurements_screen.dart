import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/models/body_measurement.dart';
import '../../../shared/utils/dates.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/weight_wheel.dart';
import '../data/measurement_units.dart';
import '../data/measurements_repository.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';
import '../../../shared/widgets/glass_dialog.dart';

/// The result of the measurement entry dialog. Wrapped in a record so that
/// "cleared" (a null value) is distinguishable from "cancelled" (a null result).
typedef _MeasurementInput = ({double? value});

/// Body measurements input: pick a day and fill in whatever you measured.
///
/// Every field is optional and saved on its own, so a half-finished day is a
/// normal state rather than something to be validated away.
class MeasurementsScreen extends ConsumerStatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  ConsumerState<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends ConsumerState<MeasurementsScreen> {
  late DateTime _day = dateOnly(DateTime.now());

  void _shiftDay(int deltaDays) {
    setState(() => _day = _day.add(Duration(days: deltaDays)));
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(measurementHistoryProvider);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Measurements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'History',
            onPressed: () => context.go('/progress/measurements/history'),
          ),
        ],
      ),
      // The day stepper is fixed, so it is held clear of the app bar; only the
      // list below it slides under the bars.
      body: (context) => Padding(
        padding: topBarInset(context),
        child: Column(
          children: [
            _DayNavigator(
              day: _day,
              onPrevious: () => _shiftDay(-1),
              // Measuring yourself in the future isn't a thing.
              onNext: _day.isBefore(dateOnly(DateTime.now()))
                  ? () => _shiftDay(1)
                  : null,
            ),
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load measurements.\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (rows) =>
                    _DayForm(day: _day, rows: rows, onEdit: _editField),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editField(
    MeasurementField field,
    double? current,
    double? suggestion,
  ) async {
    final input = await showDialog<_MeasurementInput>(
      context: context,
      builder: (context) => _MeasurementDialog(
        field: field,
        current: current,
        suggestion: suggestion,
        unit: ref.read(weightUnitProvider),
      ),
    );
    if (input == null) return; // cancelled

    await ref
        .read(measurementsRepositoryProvider)
        .setField(day: _day, field: field, value: input.value);
  }
}

class _DayNavigator extends StatelessWidget {
  const _DayNavigator({
    required this.day,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime day;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
            tooltip: 'Previous day',
          ),
          Text(formatDayLabel(day), style: theme.textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            tooltip: 'Next day',
          ),
        ],
      ),
    );
  }
}

/// The list of measurement fields for one day.
class _DayForm extends StatelessWidget {
  const _DayForm({required this.day, required this.rows, required this.onEdit});

  final DateTime day;
  final List<BodyMeasurement> rows;

  /// Called with the field, its value today, and the last known value to
  /// pre-fill with when today is blank.
  final void Function(MeasurementField field, double? current, double? previous)
  onEdit;

  BodyMeasurement? get _today {
    final target = dateOnly(day);
    for (final row in rows) {
      if (dateOnly(row.date) == target) return row;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = _today;

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 24) + bottomBarInset(context),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            row != null
                ? 'Last updated ${formatDateTime(row.updatedAt)}'
                : 'Nothing measured on this day yet — tap a row to add it.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final field in MeasurementField.values)
          FadeSlideIn(
            child: _FieldTile(
              field: field,
              current: row == null ? null : valueOf(row, field),
              previous: previousValue(rows, field, day),
              onTap: onEdit,
            ),
          ),
      ],
    );
  }
}

class _FieldTile extends ConsumerWidget {
  const _FieldTile({
    required this.field,
    required this.current,
    required this.previous,
    required this.onTap,
  });

  final MeasurementField field;
  final double? current;
  final ({double value, DateTime day})? previous;
  final void Function(MeasurementField field, double? current, double? previous)
  onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final unit = ref.watch(weightUnitProvider);
    // The change is computed in display units so it matches the two numbers
    // either side of it — a 1 lb gain shouldn't read as "+0.5".
    final delta = current != null && previous != null
        ? field.displayValue(current!, unit) -
              field.displayValue(previous!.value, unit)
        : null;

    return AppTile(
      icon: _iconFor(field),
      title: field.label,
      subtitle: previous == null
          ? null
          : 'Was ${field.formatWithUnit(previous!.value, unit)} '
                'on ${formatShortDate(previous!.day)}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (delta != null && delta != 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                // No judgement on direction — up is good for arms, bad for
                // waist, and only the user knows which they're after.
                '${delta > 0 ? '+' : '−'}${formatWeight(delta.abs())}',
                style: theme.textTheme.bodySmall?.copyWith(color: accent),
              ),
            ),
          Text(
            current == null ? '—' : field.formatWithUnit(current!, unit),
            style: theme.textTheme.titleMedium?.copyWith(
              color: current == null
                  ? theme.colorScheme.onSurfaceVariant
                  : null,
            ),
          ),
        ],
      ),
      onTap: () => onTap(field, current, previous?.value),
    );
  }
}

/// A glyph per measurement, so the rows are distinguishable at a glance rather
/// than being six identical squares down the left edge.
IconData _iconFor(MeasurementField field) => switch (field) {
  MeasurementField.weight => Icons.monitor_weight_outlined,
  MeasurementField.chest => Icons.airline_seat_flat_outlined,
  MeasurementField.waist => Icons.straighten,
  MeasurementField.hips => Icons.accessibility_new,
  MeasurementField.arms => Icons.fitness_center,
  MeasurementField.legs => Icons.directions_walk,
};

/// Number entry for one measurement. Pre-fills with today's value, or the last
/// known one, so a small change is a couple of keystrokes.
/// Talks to the user in [unit] for the weight field, in centimetres otherwise;
/// takes and returns stored values either way.
class _MeasurementDialog extends StatefulWidget {
  const _MeasurementDialog({
    required this.field,
    required this.current,
    required this.suggestion,
    required this.unit,
  });

  final MeasurementField field;
  final double? current;
  final double? suggestion;
  final WeightUnit unit;

  @override
  State<_MeasurementDialog> createState() => _MeasurementDialogState();
}

class _MeasurementDialogState extends State<_MeasurementDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: switch (widget.current ?? widget.suggestion) {
      final double v => widget.field.formatValue(v, widget.unit),
      null => '',
    },
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The wheel's value, in the display unit. Zero means "not set", matching the
  /// empty text field the other fields use.
  late double _wheelWeight = widget.field.displayValue(
    widget.current ?? widget.suggestion ?? 0,
    widget.unit,
  );

  void _save() => Navigator.of(context).pop((
    // Converted on the way out, so the weight field stores kilograms whatever
    // unit it was picked in.
    value: widget.field.isWeight
        ? (_wheelWeight <= 0
              ? null
              : widget.field.storedValue(_wheelWeight, widget.unit))
        : widget.field.parseStored(_controller.text, widget.unit),
  ));

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: Text(widget.field.label),
      // Only bodyweight gets the wheel. The others are centimetres, and a drum
      // of quarter-kilos would be offering the wrong steps in the wrong unit —
      // a circumference wheel is its own job, not this one.
      content: widget.field.isWeight
          ? WeightWheel(
              initialWeight: _wheelWeight,
              unit: widget.unit,
              label: widget.field.label,
              onChanged: (value) => _wheelWeight = value,
            )
          : TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: widget.field.label,
                suffixText: widget.field.labelIn(widget.unit),
              ),
              onSubmitted: (_) => _save(),
            ),
      actions: [
        if (widget.current != null)
          TextButton(
            // Clearing sends an explicit null, which wipes just this field.
            onPressed: () => Navigator.of(context).pop((value: null)),
            child: const Text('Clear'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
