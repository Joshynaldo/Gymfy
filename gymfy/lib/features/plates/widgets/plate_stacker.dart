import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../exercises/data/exercise_repository.dart';
import '../data/plate_math.dart';
import 'barbell_diagram.dart';

/// Builds a weight by stacking plates, instead of typing a number.
///
/// The reverse of the plate calculator: there you know the weight and want the
/// plates, here you know the plates — they're on the bar in front of you — and
/// want the weight. Tapping a plate adds one to *each* side, because that's how
/// plates go on, and the total updates as you go.
///
/// Reports through [onChanged] rather than owning the answer, so the caller
/// (the log-set dialog) keeps a single source of truth for the set's weight.
class PlateStacker extends ConsumerStatefulWidget {
  const PlateStacker({
    super.key,
    required this.initialWeight,
    required this.onChanged,
    this.exerciseId,
  });

  /// The exercise being loaded, when there is one.
  ///
  /// An id rather than the row, because the row is *watched* here. Passing the
  /// `Exercise` down was the first version and it was broken: changing the bar
  /// wrote to the database, but the dialog was holding a snapshot taken when it
  /// opened, so the number on screen never moved and the choice looked like it
  /// had been ignored.
  ///
  /// Null from the standalone calculator, which has no exercise in hand.
  final String? exerciseId;

  /// Starting total in the display unit. Decomposed back into plates so
  /// reopening a set you've already logged shows the bar as you loaded it.
  final double initialWeight;

  /// Called with the new total whenever the stack changes.
  final ValueChanged<double> onChanged;

  @override
  ConsumerState<PlateStacker> createState() => _PlateStackerState();
}

class _PlateStackerState extends ConsumerState<PlateStacker> {
  /// Plates on one side, once the user has touched something.
  List<double> _perSide = const [];

  /// Until the first tap, the stack is *derived* from [PlateStacker.initialWeight]
  /// on every build rather than seeded once.
  ///
  /// The settings this depends on — the unit, the bar, the inventory — arrive
  /// from the database a frame or two after the first build. Seeding eagerly
  /// decomposed a pound weight with kilogram plates and then kept that stack
  /// when the real settings landed, silently reporting the wrong weight.
  bool _touched = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final available = ref.watch(availablePlatesProvider);
    final id = widget.exerciseId;
    final bar = barForExercise(
      id == null ? null : ref.watch(exerciseProvider(id)).value?.barWeightKg,
      ref.watch(barWeightProvider),
      unit,
    );

    // Changing the bar changes the total without touching a single plate, so
    // the caller has to be told — otherwise the dialog would log the weight
    // from before the change while showing the one after it.
    if (id != null) {
      ref.listen(exerciseProvider(id), (previous, _) {
        _freezeStack(previous?.value?.barWeightKg, unit);
        _report();
      });
    }

    final perSide = _touched
        ? _perSide
        : calculatePlates(
            target: widget.initialWeight,
            bar: bar,
            plates: available,
          ).perSide;

    final total = bar + perSide.fold<double>(0, (sum, p) => sum + p) * 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              formatWeight(total),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Text(unit.label, style: theme.textTheme.titleMedium),
            const Spacer(),
            if (perSide.isNotEmpty)
              TextButton(
                onPressed: () => _update(const []),
                child: const Text('Clear'),
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                // The bar is stated because it's the part you can't see on the
                // screen and the part people forget.
                bar == 0
                    ? '${formatWeight(total)} ${unit.label} in plates, no bar'
                    : 'Bar ${formatPlate(bar)} ${unit.label} + '
                          '${formatWeight(total - bar)} in plates',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // Only where there is an exercise to remember the answer against.
            // The standalone calculator keeps its own picker.
            if (id != null)
              _BarButton(exerciseId: id, current: bar, unit: unit),
          ],
        ),
        const SizedBox(height: 12),
        BarbellDiagram(
          perSide: perSide,
          heaviest: available.isEmpty ? 0 : available.first,
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to add a plate to each side',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final plate in available)
              _PlateButton(
                weight: plate,
                unit: unit,
                count: perSide.where((p) => p == plate).length,
                onAdd: () => _update([...perSide, plate]),
                onRemove: () => _remove(perSide, plate),
              ),
          ],
        ),
      ],
    );
  }

  void _update(List<double> perSide) {
    _touched = true;
    // Heaviest first, so the drawing matches how a bar is actually loaded no
    // matter which order the buttons were tapped in.
    final sorted = [...perSide]..sort((a, b) => b.compareTo(a));
    setState(() => _perSide = sorted);
    _report();
  }

  /// Pins the plates currently on screen before the bar changes underneath
  /// them.
  ///
  /// Until the first tap the stack is derived from the incoming weight, so
  /// changing the bar would re-derive it — take the 20 kg bar off a 100 kg leg
  /// press and it would quietly re-arrange 40 a side into 50 a side to keep the
  /// total at 100. But the plates are physical: they are on the machine, and
  /// they did not move because you corrected a setting. Freezing them means the
  /// picture stays put and the *total* is what changes, which is the answer
  /// you went looking for.
  void _freezeStack(double? previousBarKg, WeightUnit unit) {
    if (_touched) return;
    _perSide = calculatePlates(
      target: widget.initialWeight,
      bar: barForExercise(previousBarKg, ref.read(barWeightProvider), unit),
      plates: ref.read(availablePlatesProvider),
    ).perSide;
    _touched = true;
  }

  /// Tells the caller what the stack currently weighs.
  ///
  /// Reads the *exercise's* bar, not the gym-wide one. Reading the global
  /// default here while the display above used the exercise's would report a
  /// weight one bar away from the one on screen.
  void _report() {
    final id = widget.exerciseId;
    final effective = barForExercise(
      id == null ? null : ref.read(exerciseProvider(id)).value?.barWeightKg,
      ref.read(barWeightProvider),
      ref.read(weightUnitProvider),
    );
    // Before the first tap the stack on screen is derived from the incoming
    // weight rather than held in [_perSide], so reporting the field alone
    // would say "just the bar" for a set that clearly shows plates.
    final perSide = _touched
        ? _perSide
        : calculatePlates(
            target: widget.initialWeight,
            bar: effective,
            plates: ref.read(availablePlatesProvider),
          ).perSide;

    widget.onChanged(
      effective + perSide.fold<double>(0, (sum, p) => sum + p) * 2,
    );
  }

  void _remove(List<double> perSide, double plate) {
    final next = [...perSide];
    next.remove(plate); // removes one occurrence
    _update(next);
  }
}

/// One plate denomination, in its real colour, with a badge for how many are on
/// the bar. Tap to add, long-press to take one off.
class _PlateButton extends StatelessWidget {
  const _PlateButton({
    required this.weight,
    required this.unit,
    required this.count,
    required this.onAdd,
    required this.onRemove,
  });

  final double weight;
  final WeightUnit unit;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = plateColor(weight, unit);
    final onColor = plateNeedsDarkLabel(color) ? Colors.black87 : Colors.white;

    return Semantics(
      button: true,
      label: '${formatPlate(weight)} ${unit.label}, $count on the bar',
      child: InkWell(
        onTap: onAdd,
        onLongPress: count > 0 ? onRemove : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: count > 0
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.outlineVariant,
              width: count > 0 ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formatPlate(weight),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: onColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // The count only appears once there's something to count, so an
              // untouched row of plates stays quiet.
              if (count > 0)
                Text(
                  '×$count',
                  style: theme.textTheme.labelSmall?.copyWith(color: onColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Changes which bar this exercise sits on, and remembers the answer.
///
/// Lives here rather than in the plate calculator's settings because the bar is
/// a property of the equipment, not of the gym: a barbell row and a plate-loaded
/// T-bar row are both "plate-loaded" and take different bars. One shared setting
/// could only ever be right for one of them.
class _BarButton extends ConsumerWidget {
  const _BarButton({
    required this.exerciseId,
    required this.current,
    required this.unit,
  });

  final String exerciseId;

  /// The bar currently in effect, in display units.
  final double current;

  final WeightUnit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<double>(
      tooltip: 'Change the bar',
      onSelected: (bar) => ref
          .read(exerciseRepositoryProvider)
          // Stored in kilograms like every other weight, so switching the
          // display unit later cannot turn a 20 kg bar into a 20 lb one.
          .setBarWeight(
            exerciseId,
            bar == 0 ? 0 : weightToKilograms(bar, unit),
          ),
      itemBuilder: (context) => [
        for (final bar in barOptionsFor(unit))
          PopupMenuItem(
            value: bar,
            child: Row(
              children: [
                Icon(bar == current ? Icons.check : null, size: 18),
                const SizedBox(width: 8),
                Text(formatBar(bar, unit)),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatBar(current, unit),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}
