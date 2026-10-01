import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_sheet.dart';
import '../../plates/data/plate_math.dart';
import '../data/logging_preferences.dart';
import '../data/warmup_calculator.dart';

/// Opens the warm-up calculator for [exercise] and returns the ramp sets the
/// user chose to log, or null if they closed it.
///
/// [workingKg] is the best guess at today's working weight (it stays
/// editable); [bar] and [plates] are in [unit], already resolved for this
/// exercise. Every returned step is logged by the caller as a warm-up.
Future<List<WarmupStep>?> showWarmupCalculator({
  required BuildContext context,
  required Exercise exercise,
  required double workingKg,
  required WeightUnit unit,
  required List<int> ramp,
  required List<double> plates,
  required double bar,
}) {
  return showGlassSheet<List<WarmupStep>>(
    context: context,
    handle: true,
    child: WarmupCalculatorPanel(
      exercise: exercise,
      workingKg: workingKg,
      unit: unit,
      ramp: ramp,
      plates: plates,
      bar: bar,
    ),
  );
}

/// The calculator's content: the working weight, the ramp it implies, and a
/// button that logs the chosen steps.
///
/// Public so it can be tested without a sheet around it.
class WarmupCalculatorPanel extends StatefulWidget {
  const WarmupCalculatorPanel({
    super.key,
    required this.exercise,
    required this.workingKg,
    required this.unit,
    required this.ramp,
    required this.plates,
    required this.bar,
  });

  final Exercise exercise;

  /// In kilograms, as stored.
  final double workingKg;
  final WeightUnit unit;
  final List<int> ramp;

  /// In [unit].
  final List<double> plates;
  final double bar;

  @override
  State<WarmupCalculatorPanel> createState() => _WarmupCalculatorPanelState();
}

class _WarmupCalculatorPanelState extends State<WarmupCalculatorPanel> {
  late double _workingKg = widget.workingKg;
  late final _controller = TextEditingController(text: _shown(_workingKg));

  /// Steps the user unticked, by position in the current ramp. Cleared
  /// whenever the working weight changes, because the ramp is a different
  /// list then and position 2 is no longer the step that was unticked.
  final _skipped = <int>{};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _shown(double kg) {
    if (kg <= 0) return '';
    final value = weightIn(kg, widget.unit);
    final rounded = (value * 100).round() / 100;
    return rounded == rounded.roundToDouble()
        ? '${rounded.round()}'
        : '$rounded';
  }

  /// One tap's worth of change: a pair of the smallest plates on a bar,
  /// otherwise a step a dumbbell rack or a machine stack actually makes.
  double get _stepInUnit {
    if (widget.exercise.isPlateLoaded && widget.plates.isNotEmpty) {
      final smallest = widget.plates.reduce((a, b) => a < b ? a : b);
      return smallest * 2;
    }
    return widget.unit == WeightUnit.kg ? 2.5 : 5;
  }

  void _setWorking(double kg, {bool updateField = true}) {
    setState(() {
      _workingKg = kg < 0 ? 0 : kg;
      _skipped.clear();
      if (updateField) _controller.text = _shown(_workingKg);
    });
  }

  void _nudge(int direction) {
    HapticFeedback.selectionClick();
    final shown = weightIn(_workingKg, widget.unit) + direction * _stepInUnit;
    _setWorking(weightToKilograms(shown < 0 ? 0 : shown, widget.unit));
  }

  List<WarmupStep> get _steps => planWarmups(
    workingKg: _workingKg,
    percents: widget.ramp,
    unit: widget.unit,
    plateLoaded: widget.exercise.isPlateLoaded,
    plates: widget.plates,
    bar: widget.bar,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final steps = _steps;
    final chosen = [
      for (final (index, step) in steps.indexed)
        if (!_skipped.contains(index)) step,
    ];

    return SingleChildScrollView(
      // Keeps the weight field above the keyboard when it is being typed in.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Warm-up calculator',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${widget.exercise.name} · ramp ${formatWarmupRamp(widget.ramp)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 18),
            Text(
              'WORKING WEIGHT',
              style: theme.textTheme.labelSmall?.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  tooltip: 'Lighter',
                  onPressed: _workingKg > 0 ? () => _nudge(-1) : null,
                ),
                Expanded(
                  child: TextField(
                    key: const ValueKey('warmup-working-weight'),
                    controller: _controller,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: widget.unit.label,
                      border: InputBorder.none,
                    ),
                    onChanged: (text) {
                      final value = parseWeight(text);
                      _setWorking(
                        value == null
                            ? 0
                            : weightToKilograms(value, widget.unit),
                        updateField: false,
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Heavier',
                  onPressed: () => _nudge(1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (steps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _workingKg <= 0
                      ? 'Enter the weight you are working up to.'
                      : 'Too light to need a ramp — go straight to work.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              )
            else
              for (final (index, step) in steps.indexed)
                _StepRow(
                  step: step,
                  unit: widget.unit,
                  selected: !_skipped.contains(index),
                  onChanged: (on) => setState(() {
                    if (on) {
                      _skipped.remove(index);
                    } else {
                      _skipped.add(index);
                    }
                  }),
                ),
            const SizedBox(height: 14),
            AppButton(
              label: chosen.length == 1
                  ? 'Log 1 warm-up set'
                  : 'Log ${chosen.length} warm-up sets',
              icon: Icons.check,
              height: 52,
              onPressed: chosen.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(chosen),
            ),
          ],
        ),
      ),
    );
  }
}

/// One ramp step: what to lift, how many times, and what goes on the bar.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.unit,
    required this.selected,
    required this.onChanged,
  });

  final WarmupStep step;
  final WeightUnit unit;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final plates = groupPlates(step.perSide)
        .map(
          (p) => p.count == 1
              ? formatPlate(p.plate)
              : '${formatPlate(p.plate)} × ${p.count}',
        )
        .join(' + ');

    return CheckboxListTile(
      value: selected,
      onChanged: (value) => onChanged(value ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      title: Text(
        '${formatWeightUnit(step.weightKg, unit)} × ${step.reps}',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      subtitle: Text(
        step.isEmptyBar
            ? 'Empty bar'
            : plates.isEmpty
            ? '${step.percent} %'
            : '${step.percent} % · $plates per side',
        style: theme.textTheme.bodySmall?.copyWith(color: muted),
      ),
    );
  }
}
