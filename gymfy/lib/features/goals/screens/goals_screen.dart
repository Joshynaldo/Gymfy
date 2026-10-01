import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/glass.dart';
import '../../../shared/models/goal.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/glass_icon_button.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../shared/widgets/glass_sheet.dart';
import '../data/goal_progress.dart';
import '../data/goal_repository.dart';
import '../widgets/goal_celebration.dart';
import '../widgets/goal_form.dart';
import '../widgets/goal_progress_row.dart';

/// Every goal: the ones being worked on, the ones reached, the ones put away.
///
/// Reachable from the goals card on Home and from Progress → All-time, so it
/// is served at a path under each tab rather than dragging one tab into the
/// other.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(goalStatusesProvider);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Goals'),
        actions: [
          GlassIconButton(
            icon: Icons.add,
            tooltip: 'New goal',
            onPressed: () => showGoalForm(context),
          ),
        ],
      ),
      body: (context) {
        if (statuses == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (statuses.isEmpty) return const _NoGoals();

        final celebrating = [
          for (final s in statuses)
            if (s.celebrate) s,
        ];
        final working = [
          for (final s in statuses)
            if (s.inProgress) s,
        ];
        final reached = [
          for (final s in statuses)
            if (!s.archived && !s.inProgress) s,
        ];
        final archived = [
          for (final s in statuses)
            if (s.archived) s,
        ];

        return ListView(
          padding:
              const EdgeInsets.only(top: 4, bottom: 24) + barInsets(context),
          children: [
            for (final status in celebrating)
              GoalCelebration(
                key: ValueKey('celebrate-${status.goal.id}'),
                status: status,
              ),
            if (working.isNotEmpty) ...[
              AppSectionHeader(title: 'Working on', count: working.length),
              for (final status in working) _GoalTile(status: status),
            ],
            if (reached.isNotEmpty) ...[
              AppSectionHeader(title: 'Reached', count: reached.length),
              for (final status in reached) _GoalTile(status: status),
            ],
            if (archived.isNotEmpty) ...[
              AppSectionHeader(title: 'Archived', count: archived.length),
              for (final status in archived) _GoalTile(status: status),
            ],
          ],
        );
      },
    );
  }
}

/// One goal on the Goals screen: tap to change it, the dots for the rest.
class _GoalTile extends ConsumerWidget {
  const _GoalTile({required this.status});

  final GoalStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archived = status.archived;

    return Opacity(
      // Put away, and looks it — but still legible, since the point of
      // keeping an archived goal is being able to read it.
      opacity: archived ? 0.6 : 1,
      child: AppCard(
        tier: GlassTier.quiet,
        padding: const EdgeInsets.fromLTRB(16, 14, 4, 12),
        onTap: archived
            ? null
            : () => showGoalForm(context, editing: status.goal),
        child: Row(
          children: [
            Expanded(child: GoalProgressRow(status: status)),
            IconButton(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showActions(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) {
    final goals = ref.read(goalRepositoryProvider);
    final id = status.goal.id;

    return showGlassSheet<void>(
      context: context,
      child: Builder(
        builder: (sheetContext) {
          void close() => Navigator.of(sheetContext).pop();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!status.archived)
                AppTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit',
                  trailing: null,
                  onTap: () {
                    close();
                    showGoalForm(context, editing: status.goal);
                  },
                ),
              AppTile(
                icon: status.archived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
                title: status.archived ? 'Restore' : 'Archive',
                subtitle: status.archived
                    ? 'Back on Home and in the list'
                    : 'Off Home, kept here for the record',
                trailing: null,
                onTap: () {
                  close();
                  status.archived ? goals.unarchive(id) : goals.archive(id);
                },
              ),
              AppTile(
                icon: Icons.delete_outline,
                title: 'Delete',
                trailing: null,
                onTap: () async {
                  close();
                  if (await _confirmDelete(context)) await goals.delete(id);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: const Text('Delete this goal?'),
        content: Text(
          status.kind == GoalKind.frequency
              ? 'Your workouts stay as they are. Only the goal goes.'
              : 'Your log stays as it is. Archive it instead to keep it on '
                    'record.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

/// No goals at all yet.
class _NoGoals extends StatelessWidget {
  const _NoGoals();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 24) + barInsets(context),
      children: [
        Icon(
          Icons.flag_outlined,
          size: 56,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          'No goals yet',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'A weight on a lift by a date, a number of workouts every week, or '
          'a bodyweight to reach. Progress fills in from what you log.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Set a goal',
          icon: Icons.flag_outlined,
          onPressed: () => showGoalForm(context),
        ),
      ],
    );
  }
}
