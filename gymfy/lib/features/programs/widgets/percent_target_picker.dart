import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../overload/data/percent_target.dart';
import '../../plates/data/plate_math.dart';

/// Percentages offered as chips. A stored value outside the list (an imported
/// programme at 72.5 %) gets a chip of its own rather than being snapped to a
/// neighbour the moment the dialog opens.
const percentTargetChoices = [60.0, 65.0, 70.0, 75.0, 80.0, 85.0, 90.0];

/// Picks a planned exercise's percentage-of-1RM target, and shows the weight
/// it works out to today.
///
/// Its own widget so the day builder's sets-and-reps dialog only has to hold
/// the chosen value; the 1RM lookup and the rounding live here.
class PercentTargetPicker extends StatelessWidget {
  const PercentTargetPicker({
    super.key,
    required this.exercise,
    required this.value,
    required this.onChanged,
  });

  final Exercise exercise;

  /// The current choice, 0–100, or null for "no percentage target".
  final double? value;

  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final options = {...percentTargetChoices, ?value}.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.programsPercentOfMax, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            AppChip(
              label: l10n.commonOff,
              selected: value == null,
              onTap: () => onChanged(null),
            ),
            for (final percent in options)
              AppChip(
                label: formatPercent(percent, l10n: l10n),
                selected: value == percent,
                onTap: () => onChanged(percent),
              ),
          ],
        ),
        if (value != null) ...[
          const SizedBox(height: 8),
          PercentTargetPreview(exercise: exercise, percent: value!),
        ],
      ],
    );
  }
}

/// "≈ 82.5 kg today, from your 1RM of 110 kg" — or why there is no number yet.
class PercentTargetPreview extends ConsumerWidget {
  const PercentTargetPreview({
    super.key,
    required this.exercise,
    required this.percent,
  });

  final Exercise exercise;
  final double percent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final unit = ref.watch(weightUnitProvider);
    final oneRm = ref.watch(workingOneRmProvider(exercise.id)).value;

    final String text;
    if (oneRm == null) {
      // Said plainly, because the alternative is a percentage that silently
      // does nothing and a user who thinks the feature is broken.
      text = l10n.programsPercentNoMax;
    } else {
      final weight = nearestLoadable(
        kilograms: percentOfMaxKg(oneRmKg: oneRm, percent: percent),
        plateLoaded: exercise.isPlateLoaded,
        unit: unit,
        plates: ref.watch(availablePlatesProvider),
        bar: barForExercise(
          exercise.barWeightKg,
          ref.watch(barWeightProvider),
          unit,
        ),
      );
      text = l10n.programsPercentPreview(
        formatWeightUnit(weight, unit, l10n: l10n),
        formatWeightUnit(oneRm, unit, l10n: l10n),
      );
    }

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
