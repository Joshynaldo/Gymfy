import 'package:flutter/material.dart';

import '../utils/exercise_display.dart';
import 'app_chip.dart';

/// How tall the chip row is.
///
/// Thirty-six, which is the label plus eight either side — a pill sized to
/// its text rather than to a comfortable-looking round number. It was 44,
/// and because a horizontal `ListView` hands its children a *tight* cross-
/// axis constraint, that 44 became the height of every chip: a 20px word in
/// a 44px pill, twelve pixels of air above and below it. The chip's own
/// vertical padding had nothing to do with it and changing that did nothing,
/// which is why this took three attempts to find.
///
/// Exported because an app bar hosting one has to declare its own height up
/// front, and a hand-copied number there is exactly what drifted before: the
/// header claimed 108 against 102 of content, leaving six pixels of dead
/// space under the chips.
const filterBarHeight = 36.0;

/// A horizontal row of muscle filter chips, led by an "All" chip.
///
/// Several can be on at once; the selected ones are pulled to the front so a
/// choice made after scrolling right doesn't disappear off-screen when you
/// scroll back.
///
/// Shared by the Exercises tab and the exercise picker, so filtering feels the
/// same in both places.
///
/// This was briefly generalised into a `FilterChipBar<T>` so equipment could
/// have a second row of its own. Two bars stacked turned out to be the wrong
/// shape — they put two identical "All" chips directly above each other,
/// meaning different things — so equipment moved behind a button and this
/// went back to being what it is: one bar, for muscles.
class MuscleFilterBar extends StatelessWidget {
  const MuscleFilterBar({
    super.key,
    required this.muscles,
    required this.selected,
    required this.onToggle,
    required this.onClear,
    this.leading,
  });

  /// Sits before the "All" chip and scrolls with the row.
  ///
  /// The equipment filter lives here rather than up in the app bar. Both
  /// narrow the same list, so they belong next to each other — in the bar it
  /// reads as one row of filters, and up in the chrome it read as an unrelated
  /// action that happened to change the results.
  final Widget? leading;

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
      height: filterBarHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          ?leading,
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
