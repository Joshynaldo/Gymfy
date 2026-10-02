import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/glass.dart';
import '../../../l10n/l10n.dart';
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
    final l10n = context.l10n;
    final statuses = ref.watch(goalStatusesProvider);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(l10n.goalsTitle),
        actions: [
          GlassIconButton(
            icon: LucideIcons.plus,
            tooltip: l10n.goalsNew,
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
              AppSectionHeader(
                title: l10n.goalsSectionWorking,
                count: working.length,
              ),
              for (final status in working) _GoalTile(status: status),
            ],
            if (reached.isNotEmpty) ...[
              AppSectionHeader(
                title: l10n.goalsSectionReached,
                count: reached.length,
              ),
              for (final status in reached) _GoalTile(status: status),
            ],
            if (archived.isNotEmpty) ...[
              AppSectionHeader(
                title: l10n.goalsSectionArchived,
                count: archived.length,
              ),
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
              tooltip: context.l10n.goalsActionsTooltip,
              icon: const Icon(LucideIcons.ellipsisVertical),
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
          final l10n = sheetContext.l10n;
          void close() => Navigator.of(sheetContext).pop();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!status.archived)
                AppTile(
                  icon: LucideIcons.pencil,
                  title: l10n.commonEdit,
                  trailing: null,
                  onTap: () {
                    close();
                    showGoalForm(context, editing: status.goal);
                  },
                ),
              AppTile(
                icon: status.archived
                    ? LucideIcons.archiveRestore
                    : LucideIcons.archive,
                title: status.archived ? l10n.goalsRestore : l10n.goalsArchive,
                subtitle: status.archived
                    ? l10n.goalsRestoreSubtitle
                    : l10n.goalsArchiveSubtitle,
                trailing: null,
                onTap: () {
                  close();
                  status.archived ? goals.unarchive(id) : goals.archive(id);
                },
              ),
              AppTile(
                icon: LucideIcons.trash2,
                title: l10n.commonDelete,
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
        title: Text(context.l10n.goalsDeleteTitle),
        content: Text(
          status.kind == GoalKind.frequency
              ? context.l10n.goalsDeleteFrequencyMessage
              : context.l10n.goalsDeleteMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.commonDelete),
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
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 24) + barInsets(context),
      children: [
        Icon(
          LucideIcons.flag,
          size: 56,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.goalsEmptyTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.goalsEmptyMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: l10n.goalsSetGoal,
          icon: LucideIcons.flag,
          onPressed: () => showGoalForm(context),
        ),
      ],
    );
  }
}
