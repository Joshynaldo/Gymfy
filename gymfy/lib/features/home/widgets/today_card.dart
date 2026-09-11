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
import '../../../shared/widgets/app_card.dart';
import '../../../app/theme/motion.dart';

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

    final day = dayAsync.value;

    // The four states, each with a key naming it. The key is what lets the
    // switcher below tell "the same card with new numbers" from "a different
    // card" — without one it would cross-fade every time the volume ticked.
    final (String state, Widget card) = switch (null) {
      // Held back until the query answers, rather than flashing "Rest day" and
      // correcting itself a frame later.
      _ when dayAsync.isLoading => (
        'loading',
        const _CardShell(child: SizedBox(height: 96)),
      ),
      _ when activeSplit == null => (
        'no-split',
        _MessageCard(
          weekday: weekday,
          icon: Icons.help_outline,
          title: 'No active split',
          // Names what the Workout tab now asks for, so the two screens agree.
          message: 'Pick the programme you are following to plan your week.',
          actionLabel: 'Choose a split',
          onAction: () => context.go('/workout'),
        ),
      ),
      _ when day == null => (
        'rest',
        _MessageCard(
          weekday: weekday,
          icon: Icons.bedtime_outlined,
          title: 'Rest day',
          message: 'Nothing scheduled in ${activeSplit.name}.',
        ),
      ),
      _ => (
        'workout',
        _WorkoutCard(weekday: weekday, split: activeSplit, day: day),
      ),
    };

    // This card is the first thing on the Home tab and it changes underneath
    // you: the split loads, a workout starts, the day rolls over. Swapping the
    // contents between two frames reads as a glitch — as though the screen had
    // been showing the wrong thing and corrected itself. Crossing over, at the
    // size it needs, reads as the card knowing something new.
    return AnimatedSize(
      duration: motionOf(context, AppDurations.standard),
      curve: AppCurves.settle,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: motionOf(context, AppDurations.standard),
        switchInCurve: AppCurves.settle,
        switchOutCurve: AppCurves.exit,
        // The default stacks the outgoing child under the incoming one and
        // sizes to the largest. Inside an AnimatedSize that fights the resize,
        // so the outgoing card is taken out of the layout and only painted.
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [
            for (final child in previous) Positioned.fill(child: child),
            ?current,
          ],
        ),
        child: KeyedSubtree(key: ValueKey(state), child: card),
      ),
    );
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
    // AppCard, not a bare Material Card. Home was the last tab still drawing
    // its own surfaces, so its centrepiece missed the glass pane, the press
    // scale and the highlight every other card in the app has.
    return AppCard(padding: const EdgeInsets.all(16), child: child);
  }
}
