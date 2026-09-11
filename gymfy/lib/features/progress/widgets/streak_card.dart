import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_card.dart';
import '../../workout/data/session_repository.dart';

/// Days in a row, now and at your best.
///
/// The two together are the point. A current streak on its own is a verdict —
/// "3 days" after a week off reads as a failure — while the same number beside
/// a best of twenty-three reads as "you have done this before, and you are
/// doing it again". The second figure is what makes the first one safe to show.
///
/// Hidden until there is a streak to speak of, for the same reason the badge on
/// Home is: a counter reading zero is a small daily reproach, and the app has
/// nothing to be reproachful about on a rest day.
class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaks = ref.watch(workoutStreaksProvider).value;
    if (streaks == null || streaks.best == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(title: 'Streak'),
        AppPanel(
          child: Row(
            children: [
              Expanded(
                child: _Figure(days: streaks.current, label: 'current'),
              ),
              Container(
                width: 1,
                height: 44,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.10),
              ),
              Expanded(
                child: _Figure(days: streaks.best, label: 'best ever'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.days, required this.label});

  final int days;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$days ${days == 1 ? 'day' : 'days'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
