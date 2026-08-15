import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/units.dart';
import '../data/one_rm_math.dart';

/// Estimates a one-rep max from a set you've actually done.
///
/// Weight is typed; reps use a slider rather than a second keyboard field —
/// it's one thumb movement and it can't produce an out-of-range value.
class OneRmCalculatorScreen extends ConsumerStatefulWidget {
  const OneRmCalculatorScreen({super.key});

  @override
  ConsumerState<OneRmCalculatorScreen> createState() =>
      _OneRmCalculatorScreenState();
}

class _OneRmCalculatorScreenState extends ConsumerState<OneRmCalculatorScreen> {
  final _weight = TextEditingController();
  int _reps = 5;

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    // Typed in the display unit; the maths and the estimates are all kilograms.
    final weight = parseWeightAsKilograms(_weight.text, unit);
    final estimates = weight == null
        ? null
        : estimateOneRm(weight: weight, reps: _reps);

    return Scaffold(
      appBar: AppBar(title: const Text('1RM calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _weight,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Weight lifted',
                    suffixText: unit.label,
                    border: const OutlineInputBorder(),
                  ),
                  // Rebuild on every keystroke so the estimate tracks typing.
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Reps', style: theme.textTheme.titleSmall),
                    const Spacer(),
                    Text(
                      '$_reps',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _reps.toDouble(),
                  min: 1,
                  max: oneRmMaxReps.toDouble(),
                  divisions: oneRmMaxReps - 1,
                  label: '$_reps',
                  onChanged: (value) => setState(() => _reps = value.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (estimates == null)
            _Card(
              child: Text(
                'Enter the weight you lifted and how many reps you got, and '
                'the estimate appears here.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else ...[
            _Result(estimates: estimates, reps: _reps),
            const SizedBox(height: 16),
            _FormulaComparison(estimates: estimates),
            const SizedBox(height: 16),
            _PercentageTable(
              oneRm: estimates.average,
              highlightReps: _reps,
            ),
          ],
        ],
      ),
    );
  }
}

/// The headline estimate: what the formulas agree on, and how far apart they
/// are. A single number would imply a precision none of them have.
class _Result extends ConsumerWidget {
  const _Result({required this.estimates, required this.reps});

  final OneRmEstimates estimates;
  final int reps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final unit = ref.watch(weightUnitProvider);
    final oneRm = estimates.average;
    // Rounded in the display unit, so the spread reads as loadable weights.
    final low = formatWeightIn(roundToLoadable(estimates.lowest, unit), unit);
    final high = formatWeightIn(roundToLoadable(estimates.highest, unit), unit);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Estimated 1RM',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatWeightIn(roundToLoadable(oneRm, unit), unit),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(unit.label, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reps == 1
                ? 'A single rep is already your max — no estimating needed.'
                : low == high
                ? 'All three formulas agree.'
                : 'Average of ${estimates.byFormula.length} formulas • '
                      'they range $low–$high ${unit.label}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (reps > oneRmReliableReps) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Above $oneRmReliableReps reps this is a rough guess — the '
                    'formula was built from heavy sets, and high-rep sets say '
                    'more about your endurance than your max.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Each formula's answer, highest first, so the disagreement is visible.
class _FormulaComparison extends ConsumerWidget {
  const _FormulaComparison({required this.estimates});

  final OneRmEstimates estimates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final unit = ref.watch(weightUnitProvider);
    final entries = estimates.byFormula.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Formula comparison', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key.label,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          entry.key.note,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatWeightUnit(entry.value, unit),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'All three are curve fits, not measurements. They line up on heavy '
            'sets and drift apart as the reps climb — if you need the real '
            'number, test it.',
            style: theme.textTheme.bodySmall?.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

/// What that max means for your working sets.
class _PercentageTable extends ConsumerWidget {
  const _PercentageTable({required this.oneRm, required this.highlightReps});

  final double oneRm;
  final int highlightReps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('What to load', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Weights you should manage for a given rep count.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          for (var reps = 1; reps <= 10; reps++)
            _PercentageRow(
              reps: reps,
              weight: roundToPlate(weightForReps(oneRm: oneRm, reps: reps)!),
              percent: weightForReps(oneRm: oneRm, reps: reps)! / oneRm,
              // The set the user just entered, so they can see where it sits.
              highlight: reps == highlightReps,
              accent: accent,
            ),
        ],
      ),
    );
  }
}

class _PercentageRow extends ConsumerWidget {
  const _PercentageRow({
    required this.reps,
    required this.weight,
    required this.percent,
    required this.highlight,
    required this.accent,
  });

  final int reps;

  /// In kilograms, as everything on this screen is.
  final double weight;
  final double percent;
  final bool highlight;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: highlight ? accent : null,
      fontWeight: highlight ? FontWeight.w700 : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(reps == 1 ? '1 rep' : '$reps reps', style: style),
          ),
          Expanded(
            child: Text(
              '${(percent * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(formatWeightUnit(weight, unit), style: style),
        ],
      ),
    );
  }
}

/// The card shell used by every block on this screen.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
