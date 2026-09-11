import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/accent_color.dart';

/// A vertical drum of values with the centred one highlighted.
///
/// The label sits above; the caller owns the controller so it can read the
/// selection and dispose it at the right time.
///
/// The one wheel in the app. There were three — this, a private copy in the
/// day builder's sets & reps dialog, and a third inside the picker sheets —
/// all doing the same job with slightly different padding, item heights and
/// highlight colours. A control that scrolls differently in three places is
/// three controls wearing one costume.
class NumberWheel extends ConsumerStatefulWidget {
  const NumberWheel({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.labelAt,
    this.label,
    this.onChanged,
    this.height = 150,
  });

  /// Shown above the drum. Omit inside a sheet that already has a title.
  final String? label;

  final FixedExtentScrollController controller;
  final int itemCount;

  /// The text for the item at [index]. A callback rather than a list, so a
  /// 1200-item weight wheel builds only what's on screen.
  final String Function(int index) labelAt;

  final ValueChanged<int>? onChanged;
  final double height;

  @override
  ConsumerState<NumberWheel> createState() => _NumberWheelState();
}

class _NumberWheelState extends ConsumerState<NumberWheel> {
  /// Tracked so the centred value can be drawn differently from its
  /// neighbours. Seeded from the controller rather than assumed zero — these
  /// wheels routinely open partway down.
  late int _selected = widget.controller.initialItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
        ],
        // No container of its own. It used to have one, and inside a panel
        // that gave three nested rounded rectangles in almost the same grey —
        // the drum's box, the panel's box, and the selection band's box, none
        // of them far enough apart in tone to read as layers. The drum sits
        // straight on whatever surface holds it now, and the only chrome is
        // the capsule marking the answer.
        SizedBox(
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The selection capsule: a soft accent glow, no outline. An
              // outlined box here looked like a text field waiting for input
              // rather than a marker showing which row is chosen.
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: 18,
                      spreadRadius: -4,
                    ),
                  ],
                ),
              ),
              // Fades the drum out at both ends instead of slicing it off.
              // A wheel that stops at a hard edge reads as a cropped list;
              // dissolving is what makes it read as a cylinder turning.
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0, 0.28, 0.72, 1],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: ListWheelScrollView.useDelegate(
                  controller: widget.controller,
                  itemExtent: 40,
                  // Enough perspective to read as a drum without warping the
                  // outer rows into illegibility.
                  diameterRatio: 1.6,
                  physics: const FixedExtentScrollPhysics(),
                  // High enough that the neighbours stay readable: you scroll
                  // toward a number you can already see, and at 0.45 the rows
                  // either side of centre were barely legible.
                  overAndUnderCenterOpacity: 0.62,
                  onSelectedItemChanged: (index) {
                    // The click every physical dial has. In a gym, with the
                    // phone half-watched between sets, the feel of a notch
                    // passing is what tells you the value moved.
                    HapticFeedback.selectionClick();
                    setState(() => _selected = index);
                    widget.onChanged?.call(index);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: widget.itemCount,
                    builder: (context, index) {
                      final isSelected = index == _selected;
                      return Center(
                        child: Text(
                          widget.labelAt(index),
                          style: theme.textTheme.titleLarge?.copyWith(
                            // The centred value is the answer, so it is the
                            // one that reads as chosen rather than merely
                            // nearest — colour, weight and a little size.
                            color: isSelected ? accent : null,
                            fontSize: isSelected ? 23 : 20,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            fontFeatures: const [
                              // Digits must not shuffle sideways as the drum
                              // turns.
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
