import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/accent_color.dart';

/// A vertical drum of values with the centred one highlighted.
///
/// The label sits above; the caller owns the controller so it can read the
/// selection and dispose it at the right time.
///
/// Extracted from the sets/reps dialog so weight inputs look and behave exactly
/// the same — a wheel that scrolls differently in two places is two controls
/// wearing one costume.
class NumberWheel extends ConsumerWidget {
  const NumberWheel({
    super.key,
    required this.label,
    required this.controller,
    required this.itemCount,
    required this.labelAt,
    this.onChanged,
    this.height = 150,
  });

  final String label;
  final FixedExtentScrollController controller;
  final int itemCount;

  /// The text for the item at [index]. A callback rather than a list, so a
  /// 1200-item weight wheel builds only what's on screen.
  final String Function(int index) labelAt;

  final ValueChanged<int>? onChanged;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Highlight band behind the centred item.
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 40,
                physics: const FixedExtentScrollPhysics(),
                overAndUnderCenterOpacity: 0.35,
                onSelectedItemChanged: onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: itemCount,
                  builder: (context, index) => Center(
                    child: Text(
                      labelAt(index),
                      style: theme.textTheme.titleLarge,
                    ),
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
