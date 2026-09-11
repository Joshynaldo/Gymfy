// Material exports an animation curve also named `Split`; hide it so `Split`
// here unambiguously means our Drift row class.
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/weekday.dart';
import '../data/workout_repository.dart';
import '../screens/widgets/weekday_picker.dart';
import '../../../app/theme/glass.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/app_card.dart';

/// Every day of one split, as a scrollable column of cards.
///
/// Shared by the Workout tab (which shows the *active* split inline, so the
/// programme you're following is the first thing you see) and the split
/// overview screen (which shows any other split you tap into). One widget, so
/// the two can't drift into showing the same data differently.
class SplitDayList extends ConsumerWidget {
  const SplitDayList({super.key, required this.splitId});

  final int splitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(scheduledDaysProvider(splitId));

    return daysAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load this split.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (days) {
        if (days.isEmpty) return const NoDaysYet();
        return ListView(
          padding:
              const EdgeInsets.fromLTRB(12, 12, 12, 96) + barInsets(context),
          children: [
            for (final scheduled in days)
              DayCard(splitId: splitId, scheduled: scheduled),
          ],
        );
      },
    );
  }
}

/// One day, as a card: a header (name + count + actions), the weekday picker,
/// and its exercises listed underneath.
class DayCard extends ConsumerWidget {
  const DayCard({super.key, required this.splitId, required this.scheduled});

  final int splitId;
  final ScheduledDay scheduled;

  WorkoutDay get day => scheduled.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final exercisesAsync = ref.watch(dayExercisesProvider(day.id));
    final exercises = exercisesAsync.value ?? const [];
    final schedule = weekdaySummary(scheduled.weekdays);

    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Icon(Icons.today, color: accent),
            ),
            title: Text(
              day.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              [
                exercises.length == 1
                    ? '1 exercise'
                    : '${exercises.length} exercises',
                // Named explicitly rather than left blank: "not scheduled" is a
                // state worth noticing, since the day won't appear on any
                // weekday until it's fixed.
                schedule ?? 'Not scheduled',
              ].join(' • '),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete day',
              onPressed: () => _confirmDelete(context, ref),
            ),
            onTap: () => context.go('/workout/split/$splitId/day/${day.id}'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: WeekdayPicker(
              selected: scheduled.weekdays,
              onToggle: (weekday) => _toggleWeekday(ref, weekday),
            ),
          ),
          if (exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No exercises yet — tap to add some.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  for (final planned in exercises)
                    _ExerciseRow(planned: planned),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleWeekday(WidgetRef ref, int weekday) {
    final repository = ref.read(workoutRepositoryProvider);
    return scheduled.weekdays.contains(weekday)
        ? repository.clearWeekday(dayId: day.id, weekday: weekday)
        : repository.assignWeekday(dayId: day.id, weekday: weekday);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return GlassDialog(
          title: Text('Delete "${day.name}"?'),
          content: const Text(
            'This removes the day and its exercises. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await ref.read(workoutRepositoryProvider).deleteDay(day.id);
  }
}

/// A single exercise line inside a day card: name on the left, target on the
/// right (e.g. "3 × 10").
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.planned});

  final PlannedExercise planned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              planned.exercise.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatSetTarget(
              planned.entry.defaultSets,
              planned.entry.defaultReps,
              planned.entry.defaultRepsMax,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when a split exists but has no days in it yet.
class NoDaysYet extends StatelessWidget {
  const NoDaysYet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.today,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No days yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add a training day (like "Push" or "Legs") to start building '
              'this split.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
