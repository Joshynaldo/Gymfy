import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/data/settings_repository.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/weight_wheel.dart';
import '../data/plate_math.dart';
import '../widgets/barbell_diagram.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';

/// Opens the plate calculator over the current screen, prefilled with
/// [weight] in the display unit.
///
/// A push rather than a route change, so it comes back to wherever it was
/// opened from. Mid-workout that matters — switching tabs to look up plates
/// and then having to navigate back to your session is a real cost between
/// sets.
Future<void> showPlateCalculator(BuildContext context, {double? weight}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) => PlateCalculatorScreen(initialWeight: weight),
    ),
  );
}

/// Identifies the loaded total.
///
/// Public so tests can read it directly: the target wheel shows the same number
/// a moment before the bar does, so `find.text('100')` matches twice and cannot
/// tell "the answer" from "what you asked for".
const plateTotalKey = Key('plate-total');

/// Works out what to put on the bar for a target weight.
///
/// Everything on this screen is in the unit the user has chosen, with no
/// conversion anywhere: plates and bars are physical objects labelled in one
/// unit, and converting them would produce weights nobody owns. See the header
/// of plate_math.dart.
class PlateCalculatorScreen extends ConsumerStatefulWidget {
  const PlateCalculatorScreen({super.key, this.initialWeight});

  /// Prefilled target, e.g. when opened from a logged set or a 1RM estimate.
  /// In the *display* unit, since that's what the caller is showing.
  final double? initialWeight;

  @override
  ConsumerState<PlateCalculatorScreen> createState() =>
      _PlateCalculatorScreenState();
}

class _PlateCalculatorScreenState extends ConsumerState<PlateCalculatorScreen> {
  /// Target weight in the display unit. Zero means "nothing asked for yet".
  late double _target = widget.initialWeight ?? 0;

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(weightUnitProvider);
    final plates = ref.watch(availablePlatesProvider);
    final bar = ref.watch(barWeightProvider);

    return GlassScaffold(
      appBar: GlassAppBar(title: const Text('Plate calculator')),
      body: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32) + barInsets(context),
        children: [
          // The two inputs share one panel: they are a single question —
          // "what am I loading, and onto what" — and splitting them into two
          // cards made the bar look like a separate setting you had to go
          // and configure.
          AppPanel(
            icon: Icons.tune,
            title: 'What are you loading?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WeightWheel(
                  key: ValueKey(unit),
                  initialWeight: _target,
                  unit: unit,
                  label: 'Target weight',
                  onChanged: (value) => setState(() => _target = value),
                ),
                const SizedBox(height: 20),
                _BarPicker(unit: unit, selected: bar),
              ],
            ),
          ),
          if (_target <= 0)
            const _Hint(
              text: 'Dial in a target weight to see what goes on the bar.',
            )
          else
            _Result(
              load: calculatePlates(target: _target, bar: bar, plates: plates),
              unit: unit,
              heaviest: plates.isEmpty ? 0 : plates.first,
            ),
        ],
      ),
    );
  }
}

/// Which bar you're loading. The options differ per unit because a 20 kg bar
/// and a 45 lb bar are different bars, not the same one converted.
class _BarPicker extends ConsumerWidget {
  const _BarPicker({required this.unit, required this.selected});

  final WeightUnit unit;
  final double selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Includes "None". Plate-loaded does not mean barbell: a hack squat or a
    // leg press takes plates onto a carriage, and adding a bar that isn't
    // there made every total wrong by exactly one bar.
    final bars = barOptionsFor(unit);
    final key = unit == WeightUnit.kg ? barKgSetting : barLbsSetting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bar',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<double>(
            segments: [
              for (final bar in bars)
                ButtonSegment(value: bar, label: Text(formatBar(bar, unit))),
            ],
            selected: {selected},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => ref
                .read(settingsRepositoryProvider)
                .write(key, formatPlate(selection.first)),
          ),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.load,
    required this.unit,
    required this.heaviest,
  });

  final PlateLoad load;
  final WeightUnit unit;
  final double heaviest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (load.belowBar) {
      return _Hint(
        text:
            '${formatWeight(load.target)} ${unit.label} is lighter than the '
            'bar itself (${formatPlate(load.bar)} ${unit.label}).',
      );
    }

    final grouped = groupPlates(load.perSide);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The total leads. It is the number you check before you lift, and it
        // was previously at the very bottom, under the diagram and the chips.
        _TotalPanel(load: load, unit: unit),
        AppPanel(
          icon: Icons.fitness_center,
          title: 'Each side',
          // No "nothing to load" subtitle here: the diagram already says
          // "Just the bar", and saying it twice on one card reads as a bug.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BarbellDiagram(perSide: load.perSide, heaviest: heaviest),
              if (grouped.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in grouped)
                      AppChip(
                        label:
                            '${formatPlate(entry.plate)} ${unit.label} '
                            '× ${entry.count}',
                        selected: false,
                        onTap: null,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            load.isExact
                // Naming the bar separately makes the total checkable at a
                // glance — the commonest mistake is forgetting the bar.
                ? 'Bar ${formatPlate(load.bar)} + plates '
                      '${formatWeight(load.achieved - load.bar)} ${unit.label}'
                // The shortfall is stated rather than silently rounding,
                // because "closest I can load" is a different fact from "your
                // target".
                : 'Closest loadable — '
                      '${formatWeight(load.target - load.achieved)} '
                      '${unit.label} under your target of '
                      '${formatWeight(load.target)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// What the bar actually weighs once loaded.
class _TotalPanel extends ConsumerWidget {
  const _TotalPanel({required this.load, required this.unit});

  final PlateLoad load;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return AppPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'Total',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            formatWeight(load.achieved),
            key: plateTotalKey,
            style: theme.textTheme.displaySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            unit.label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: accent.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
