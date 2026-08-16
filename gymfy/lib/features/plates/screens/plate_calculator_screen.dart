import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/data/settings_repository.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/weight_wheel.dart';
import '../data/plate_math.dart';
import '../widgets/barbell_diagram.dart';

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

class _PlateCalculatorScreenState
    extends ConsumerState<PlateCalculatorScreen> {
  /// Target weight in the display unit. Zero means "nothing asked for yet".
  late double _target = widget.initialWeight ?? 0;

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(weightUnitProvider);
    final plates = ref.watch(availablePlatesProvider);
    final bar = ref.watch(barWeightProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Plate calculator')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
          const SizedBox(height: 24),
          if (_target <= 0)
            _Hint(text: 'Dial in a target weight to see what goes on the bar.')
          else
            _Result(
              load: calculatePlates(
                target: _target,
                bar: bar,
                plates: plates,
              ),
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
    final bars = unit == WeightUnit.kg ? barsKg : barsLbs;
    final key = unit == WeightUnit.kg ? barKgSetting : barLbsSetting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bar', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<double>(
          segments: [
            for (final bar in bars)
              ButtonSegment(
                value: bar,
                label: Text('${formatPlate(bar)} ${unit.label}'),
              ),
          ],
          selected: {selected},
          onSelectionChanged: (selection) => ref
              .read(settingsRepositoryProvider)
              .write(key, formatPlate(selection.first)),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Each side', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        BarbellDiagram(perSide: load.perSide, heaviest: heaviest),
        const SizedBox(height: 16),
        if (grouped.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in grouped)
                Chip(
                  label: Text(
                    '${formatPlate(entry.plate)} ${unit.label} × ${entry.count}',
                  ),
                ),
            ],
          ),
        const SizedBox(height: 20),
        _TotalRow(load: load, unit: unit),
      ],
    );
  }
}

/// What the bar actually weighs once loaded — and, when the target can't be
/// hit exactly, by how much it misses.
class _TotalRow extends ConsumerWidget {
  const _TotalRow({required this.load, required this.unit});

  final PlateLoad load;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total ${formatWeight(load.achieved)} ${unit.label}',
          style: theme.textTheme.headlineSmall?.copyWith(color: accent),
        ),
        const SizedBox(height: 4),
        Text(
          load.isExact
              // Naming the bar separately makes the total checkable at a glance
              // — the commonest mistake is forgetting the bar.
              ? 'Bar ${formatPlate(load.bar)} + plates '
                    '${formatWeight(load.achieved - load.bar)} ${unit.label}'
              // The shortfall is stated rather than silently rounding, because
              // "closest I can load" is a different fact from "your target".
              : 'Closest loadable — '
                    '${formatWeight(load.target - load.achieved)} '
                    '${unit.label} under your target of '
                    '${formatWeight(load.target)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
