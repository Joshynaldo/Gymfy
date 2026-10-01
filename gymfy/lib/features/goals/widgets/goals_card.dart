import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_card.dart';
import '../data/goal_repository.dart';
import 'goal_celebration.dart';
import 'goal_progress_row.dart';

/// How many goals the Home card lists before it says "and N more".
const homeGoalRows = 3;

/// The goals you are working on, on Home: one card, a bar each.
///
/// Renders nothing without an active goal, like every other Home card with
/// nothing to say — a fresh install is short rather than full of prompts. The
/// way in to set the first one is Progress → All-time.
///
/// A reached goal's celebration shows here above the card until it has been
/// seen, which is why the card also appears for a goal that has just been met
/// and so left the active list.
class GoalsCard extends ConsumerWidget {
  const GoalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(goalStatusesProvider);
    if (statuses == null) return const SizedBox.shrink();

    final celebrating = [
      for (final status in statuses)
        if (status.celebrate) status,
    ];
    final active = [
      for (final status in statuses)
        if (status.inProgress) status,
    ];
    if (celebrating.isEmpty && active.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final shown = active.take(homeGoalRows).toList();
    final more = active.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'Goals',
          countLabel: active.isEmpty ? null : '${active.length} active',
        ),
        for (final status in celebrating)
          GoalCelebration(
            key: ValueKey('celebrate-${status.goal.id}'),
            status: status,
          ),
        if (shown.isNotEmpty)
          AppPanel(
            onTap: () => context.go('/home/goals'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, status) in shown.indexed) ...[
                  if (index > 0) const SizedBox(height: 16),
                  // White bars: Home's one accent is the Start workout button.
                  GoalProgressRow(status: status, muted: true),
                ],
                if (more > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '+$more more',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
