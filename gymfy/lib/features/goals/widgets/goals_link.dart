import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_card.dart';
import '../data/goal_repository.dart';

/// The way to the Goals screen from Progress → All-time.
///
/// Always shown, unlike the Home card: Home stays quiet until there is a goal
/// to show, so this is where the first one gets set.
class GoalsLink extends ConsumerWidget {
  const GoalsLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(goalStatusesProvider) ?? const [];
    final active = statuses.where((s) => s.inProgress).length;
    final reached = statuses.where((s) => !s.archived && !s.inProgress).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(title: 'Goals'),
        AppTile(
          icon: Icons.flag_outlined,
          title: active == 0 ? 'Set a goal' : 'Your goals',
          subtitle: switch ((active, reached)) {
            (0, 0) => 'A lift, a weekly habit or a bodyweight to reach',
            (0, _) => '$reached reached — set the next one',
            (_, 0) => '$active in progress',
            _ => '$active in progress, $reached reached',
          },
          onTap: () => context.go('/progress/goals'),
        ),
      ],
    );
  }
}
