import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/units.dart';
import '../data/plate_math.dart';

/// One end of a loaded barbell, drawn to scale.
///
/// Only one side is shown, and it's labelled as such — a symmetrical picture
/// would double the width to say the same thing twice, and you load one side at
/// a time anyway.
///
/// Plate *height* varies with weight so the shape matches what's on the rack:
/// the tall ones are the heavy ones. Widths stay equal, because a 1.25 and a 25
/// drawn to relative thickness would make the small plate invisible.
///
/// Colours are the real competition ones (see [plateColor]) rather than the
/// accent — matching the plates in front of you is the whole point.
class BarbellDiagram extends ConsumerWidget {
  const BarbellDiagram({
    super.key,
    required this.perSide,
    required this.heaviest,
  });

  final List<double> perSide;

  /// The heaviest plate in the user's inventory, used to scale the tallest
  /// plate here. Passed in rather than taken from [perSide] so the same weight
  /// always draws the same height, instead of the biggest plate on the bar
  /// always looking full-size.
  final double heaviest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);

    return SizedBox(
      height: 132,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // The sleeve, running off the left edge toward the middle of the bar.
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(2),
                ),
              ),
            ),
          ),
          if (perSide.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Just the bar',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final plate in perSide)
              _Plate(weight: plate, heaviest: heaviest, unit: unit),
          // The collar at the end of the sleeve, so the plates read as stacked
          // against something rather than floating.
          Container(
            width: 8,
            height: 26,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({
    required this.weight,
    required this.heaviest,
    required this.unit,
  });

  final double weight;
  final double heaviest;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Floor of 0.35 so the lightest plate is still a plate and not a sliver.
    final scale = heaviest <= 0 ? 1.0 : (weight / heaviest).clamp(0.35, 1.0);
    final color = plateColor(weight, unit);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Container(
        width: 18,
        height: 132 * scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          // A white 5 kg plate on a light background would otherwise vanish.
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            formatPlate(weight),
            style: theme.textTheme.labelSmall?.copyWith(
              color: plateNeedsDarkLabel(color) ? Colors.black87 : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
