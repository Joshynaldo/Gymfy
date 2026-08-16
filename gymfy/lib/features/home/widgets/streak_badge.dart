import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../workout/data/session_repository.dart';

/// Days trained in a row, in the Home app bar.
///
/// Counts *days*, not sessions — two workouts in one day is one day of the
/// streak — and only completed ones. Starting a workout and walking out isn't
/// training, and a number that can be gamed is a number worth nothing.
///
/// Hidden entirely at zero. A streak counter reading "0" is a small daily
/// reproach, and the app has nothing to be reproachful about on a rest day or
/// on the day someone installs it.
class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final streak = ref.watch(workoutStreakProvider).value ?? 0;

    if (streak == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: Semantics(
          label: '$streak day workout streak',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department, size: 16, color: accent),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
