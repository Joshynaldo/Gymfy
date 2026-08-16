// Material exports an animation curve also named `Split`; hide it so `Split`
// here unambiguously means our Drift row class.
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/weekday.dart';
import '../../workout/data/session_repository.dart';
import '../../workout/data/workout_repository.dart';

/// The centrepiece of the Home tab: what today is.
///
/// Four states, and each says something different about what to do next:
/// no active split, a rest day, today's workout, and a workout already running.
/// "Rest" is the absence of a scheduled day rather than something stored, so
/// this can never disagree with the schedule.
class TodayCard extends ConsumerWidget {
  const TodayCard({super.key, this.today});

  /// Overridable so tests can pick a weekday instead of depending on when they
  /// happen to run — a card that only passes on Tuesdays isn't a test.
  final DateTime? today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = today ?? DateTime.now();
    final weekday = date.weekday;

    final activeSplit = ref.watch(activeSplitProvider).value;
    final dayAsync = ref.watch(dayForWeekdayProvider(weekday));

    // Held back until the query answers, rather than flashing "Rest day" and
    // correcting itself a frame later.
    if (dayAsync.isLoading) {
      return const _CardShell(child: SizedBox(height: 96));
    }
    final day = dayAsync.value;

    if (activeSplit == null) {
      return _MessageCard(
        weekday: weekday,
        icon: Icons.help_outline,
        title: 'No active split',
        message: 'Open a split and tap "Set active" to plan your week.',
        actionLabel: 'Go to splits',
        onAction: () => context.go('/workout'),
      );
    }

    if (day == null) {
      return _MessageCard(
        weekday: weekday,
        icon: Icons.bedtime_outlined,
        title: 'Rest day',
        message: 'Nothing scheduled in ${activeSplit.name}.',
      );
    }

    return _WorkoutCard(weekday: weekday, split: activeSplit, day: day);
  }
}

/// Today's training day: what's planned, and one button to get started.
class _WorkoutCard extends ConsumerWidget {
  const _WorkoutCard({
    required this.weekday,
    required this.split,
    required this.day,
  });

  final int weekday;
  final Split split;
  final WorkoutDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final planned = ref.watch(dayExercisesProvider(day.id)).value ?? const [];
    final running = ref.watch(inProgressSessionProvider).value;

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading(weekday: weekday, trailing: split.name),
          const SizedBox(height: 4),
          Text(day.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          if (planned.isEmpty)
            Text(
              'No exercises yet — open the day to add some.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final p in planned)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatSetTarget(
                        p.entry.defaultSets,
                        p.entry.defaultReps,
                        p.entry.defaultRepsMax,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 16),
          if (running != null)
            // Resuming rather than offering a second Start: two live sessions
            // would split one workout's sets across both.
            FilledButton.icon(
              onPressed: () => context.go('/workout/session/${running.id}'),
              icon: const Icon(Icons.play_arrow),
              label: Text('Resume ${running.name}'),
              style: FilledButton.styleFrom(backgroundColor: accent),
            )
          else if (planned.isNotEmpty)
            FilledButton.icon(
              onPressed: () => _start(context, ref),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start workout'),
              style: FilledButton.styleFrom(backgroundColor: accent),
            )
          else
            OutlinedButton.icon(
              onPressed: () =>
                  context.go('/workout/split/${split.id}/day/${day.id}'),
              icon: const Icon(Icons.add),
              label: const Text('Add exercises'),
            ),
        ],
      ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final sessionId = await ref
        .read(sessionRepositoryProvider)
        .startSession(dayId: day.id, name: day.name);
    router.go('/workout/session/$sessionId');
  }
}

/// The rest-day and no-split states: a short explanation, optionally with the
/// one action that fixes it.
class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.weekday,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final int weekday;
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading(weekday: weekday),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: theme.textTheme.headlineSmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The weekday, with the split name on the right when there is one.
class _Heading extends StatelessWidget {
  const _Heading({required this.weekday, this.trailing});

  final int weekday;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 1,
    );

    return Row(
      children: [
        Text(weekdayName(weekday).toUpperCase(), style: style),
        if (trailing != null) ...[
          const Spacer(),
          Flexible(
            child: Text(
              trailing!.toUpperCase(),
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
