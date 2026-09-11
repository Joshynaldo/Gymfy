import 'package:flutter/material.dart';

import '../utils/exercise_display.dart';
import 'app_chip.dart';

/// A horizontal row of muscle filter chips, led by an "All" chip.
///
/// Several can be on at once; the selected ones are pulled to the front so a
/// choice made after scrolling right doesn't disappear off-screen when you
/// scroll back.
///
/// Shared by the Exercises tab and the exercise picker, so filtering feels the
/// same in both places.
class MuscleFilterBar extends StatelessWidget {
  const MuscleFilterBar({
    super.key,
    required this.muscles,
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  /// Every muscle worth offering, already sorted — see `musclesIn`.
  final List<String> muscles;

  /// The muscles currently filtered on. Empty means "All".
  final Set<String> selected;

  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ordered = [
      ...muscles.where(selected.contains),
      ...muscles.where((m) => !selected.contains(m)),
    ];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AppChip(
              label: 'All',
              selected: selected.isEmpty,
              // Already showing everything, so this would be a no-op tap. A
              // disabled chip says "you're here" better than one that does
              // nothing when pressed.
              onTap: selected.isEmpty ? null : onClear,
            ),
          ),
          for (final muscle in ordered)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AppChip(
                label: muscleLabel(muscle),
                selected: selected.contains(muscle),
                onTap: () => onToggle(muscle),
              ),
            ),
        ],
      ),
    );
  }
}
