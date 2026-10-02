import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/goal_repository.dart';
import '../../../shared/widgets/lucide_icons.dart';

/// The way to the Goals screen from Progress → All-time.
///
/// Always shown, unlike the Home card: Home stays quiet until there is a goal
/// to show, so this is where the first one gets set.
class GoalsLink extends ConsumerWidget {
  const GoalsLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statuses = ref.watch(goalStatusesProvider) ?? const [];
    final active = statuses.where((s) => s.inProgress).length;
    final reached = statuses.where((s) => !s.archived && !s.inProgress).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.goalsTitle),
        AppTile(
          icon: LucideIcons.flag,
          title: active == 0 ? l10n.goalsSetGoal : l10n.goalsLinkYourGoals,
          subtitle: switch ((active, reached)) {
            (0, 0) => l10n.goalsLinkEmpty,
            (0, _) => l10n.goalsLinkReachedOnly(reached),
            (_, 0) => l10n.goalsLinkActiveOnly(active),
            _ => l10n.goalsLinkBoth(active, reached),
          },
          onTap: () => context.go('/progress/goals'),
        ),
      ],
    );
  }
}
