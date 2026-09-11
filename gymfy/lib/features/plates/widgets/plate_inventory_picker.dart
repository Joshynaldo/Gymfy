import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/settings_repository.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/app_chip.dart';
import '../data/plate_math.dart';

/// Which plate denominations the user's gym actually has.
///
/// Shown per unit, and only for the unit currently in use: a kilo gym and a
/// pound gym own different physical plates, so there is nothing sensible to
/// convert between the two lists. Switching units in the section above swaps
/// which inventory this edits.
class PlateInventoryPicker extends ConsumerWidget {
  const PlateInventoryPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final selected = ref.watch(availablePlatesProvider).toSet();
    final options = unit == WeightUnit.kg
        ? selectablePlatesKg
        : selectablePlatesLbs;
    final key = unit == WeightUnit.kg ? platesKgSetting : platesLbsSetting;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The plates your gym has, in ${unit.label}. The calculator only '
            'suggests these.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final plate in options)
                AppChip(
                  label: formatPlate(plate),
                  selected: selected.contains(plate),
                  onTap: () => _toggle(
                    ref,
                    key: key,
                    selected: selected,
                    plate: plate,
                    isSelected: !selected.contains(plate),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggle(
    WidgetRef ref, {
    required String key,
    required Set<double> selected,
    required double plate,
    required bool isSelected,
  }) {
    final next = {...selected};
    if (isSelected) {
      next.add(plate);
    } else {
      next.remove(plate);
    }

    final repository = ref.read(settingsRepositoryProvider);
    // Clearing the last plate stores nothing rather than an empty list, so the
    // setting falls back to the defaults. An inventory of no plates would make
    // the calculator answer "just the bar" to everything, which reads as
    // broken rather than as a choice.
    if (next.isEmpty) {
      repository.clear(key);
      return;
    }
    repository.write(key, encodePlates(next));
  }
}
