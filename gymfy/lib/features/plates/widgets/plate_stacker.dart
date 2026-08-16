import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
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
  });

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
    final bar = ref.watch(barWeightProvider);

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
        Text(
          // The bar is stated because it's the part you can't see on the
          // screen and the part people forget.
          'Bar ${formatPlate(bar)} ${unit.label} + '
          '${formatWeight(total - bar)} in plates',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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

    final bar = ref.read(barWeightProvider);
    widget.onChanged(
      bar + sorted.fold<double>(0, (sum, p) => sum + p) * 2,
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
