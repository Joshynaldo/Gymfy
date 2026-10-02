import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/session_length.dart';
import '../../../shared/widgets/animated_count.dart';
import '../../../shared/utils/units.dart';
import '../../exercises/data/exercise_repository.dart';
import '../../muscle_map/data/muscle_volume_repository.dart';
import '../../muscle_map/widgets/muscle_map_view.dart';
import '../data/personal_records.dart';
import '../data/session_repository.dart';
import '../widgets/record_celebration.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';
import '../../../shared/widgets/lucide_icons.dart';

/// Shown after finishing a workout: a recap of the session just completed —
/// duration, total sets, total volume, and a per-exercise breakdown.
///
/// Reachable via `/workout/summary/:sessionId`, so tapping the system back
/// button returns to the Workout tab home rather than the live logging screen.
///
/// Also opened from the training calendar in Progress, at
/// `/progress/session/:sessionId`, as [fromHistory]: an old workout looked up,
/// not one just finished — so it has a back arrow, and "Done" goes back to the
/// calendar instead of to the Workout tab.
class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.sessionId,
    this.fromHistory = false,
  });

  final int sessionId;
  final bool fromHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider(sessionId));

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          fromHistory
              ? context.l10n.workoutTitle
              : context.l10n.workoutSummaryTitle,
        ),
        automaticallyImplyLeading: fromHistory,
      ),
      body: (context) => sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.l10n.workoutSummaryLoadFailed('$error'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (session) {
          if (session == null) {
            return Center(child: Text(context.l10n.workoutNotFound));
          }
          return _SummaryBody(session: session, fromHistory: fromHistory);
        },
      ),
    );
  }
}

class _SummaryBody extends ConsumerWidget {
  const _SummaryBody({required this.session, required this.fromHistory});

  final WorkoutSession session;
  final bool fromHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final sets =
        ref.watch(sessionSetsProvider(session.id)).value ?? const <LoggedSet>[];
    // Names for the per-exercise breakdown; empty map until the library loads.
    // Archived exercises included on purpose — a session logged before a custom
    // exercise was deleted must still show its name, not a blank row.
    final exercises = ref.watch(allExercisesProvider).value ?? const [];
    final nameById = {for (final e in exercises) e.id: e.name};

    final totalVolume = sets.fold<double>(
      0,
      (sum, s) => sum + s.weight * s.reps,
    );

    // Group sets by exercise, preserving first-seen order.
    final byExercise = <String, List<LoggedSet>>{};
    for (final s in sets) {
      byExercise.putIfAbsent(s.exerciseId, () => []).add(s);
    }

    final duration = sessionLength(session.startedAt, session.completedAt);

    // Empty until the query lands, and empty for most sessions — the list
    // renders nothing either way, so the layout never waits on it.
    final records =
        ref.watch(sessionRecordsProvider(session.id)).value ??
        const <ExerciseRecords>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32) + barInsets(context),
      children: [
        // No flourish here. There was a bloom of light behind this header when
        // a session was finished; it was removed because it looked broken
        // rather than celebratory. The numbers are the reward.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              formatDateTime(session.startedAt, l10n: l10n),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _StatsRow(
              duration: duration,
              setCount: sets.length,
              totalVolume: totalVolume,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (records.isNotEmpty) ...[
          SessionRecordsList(records: records, nameById: nameById),
          const SizedBox(height: 24),
        ],
        if (sets.isEmpty)
          Text(l10n.workoutSummaryNoSets, style: theme.textTheme.bodyMedium)
        else ...[
          Text(
            l10n.workoutSummaryExercises,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final entry in byExercise.entries)
            _ExerciseSummaryTile(
              name: nameById[entry.key] ?? entry.key,
              sets: entry.value,
            ),
          const SizedBox(height: 24),
          Text(
            l10n.workoutSummaryMusclesWorked,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(
            height: 440,
            child: MuscleMapView(
              intensities: ref.watch(
                sessionMuscleIntensitiesProvider(session.id),
              ),
              emptyMessage: l10n.workoutSummaryNoMuscles,
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => fromHistory ? context.pop() : context.go('/workout'),
          child: Text(l10n.commonDone),
        ),
      ],
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow({
    required this.duration,
    required this.setCount,
    required this.totalVolume,
  });

  /// Null when the length was never recorded — an imported session whose file
  /// did not say. Shown as a dash rather than as zero.
  final Duration? duration;

  final int setCount;

  /// In kilograms, as stored.
  final double totalVolume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unit = ref.watch(weightUnitProvider);

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: LucideIcons.timer,
            label: l10n.workoutSummaryDuration,
            // Not counted up: a clock that races from 00:00 to your session
            // length looks like the timer is still running.
            //
            // An em dash where the length is not known. "0 min" next to
            // eighteen logged sets is a confident claim about a workout that
            // plainly took time — and it is what an imported session read as,
            // because the file it came from recorded no usable end.
            value: Text(
              duration == null ? '—' : formatDuration(duration!),
              style: _valueStyle(context),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: LucideIcons.repeat,
            label: l10n.workoutSummarySets,
            value: AnimatedCount(
              value: setCount.toDouble(),
              from: 0,
              format: (value) => '${value.round()}',
              style: _valueStyle(context),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: LucideIcons.dumbbell,
            label: l10n.workoutSummaryVolume,
            value: AnimatedCount(
              value: totalVolume,
              from: 0,
              format: (value) => formatWeightUnit(value, unit, l10n: l10n),
              style: _valueStyle(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends ConsumerWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;

  /// A widget rather than a string so two of the three can count themselves up
  /// while the third stays a plain clock.
  final Widget value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 8),
          value,
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSummaryTile extends ConsumerWidget {
  const _ExerciseSummaryTile({required this.name, required this.sets});

  final String name;
  final List<LoggedSet> sets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final unit = ref.watch(weightUnitProvider);
    final volume = sets.fold<double>(0, (sum, s) => sum + s.weight * s.reps);
    // The "top set" is the heaviest working set; ties broken by the most
    // reps. Warm-ups and drop sets only stand in when nothing else was logged,
    // matching the strength filter everywhere else.
    final working = sets.where(isWorkingSet).toList();
    final topSet = (working.isEmpty ? sets : working).reduce((a, b) {
      if (b.weight > a.weight) return b;
      if (b.weight == a.weight && b.reps > a.reps) return b;
      return a;
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: theme.textTheme.titleSmall)),
              Text(
                l10n.workoutSummaryExerciseSets(sets.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            // Through the shared formatter, so a hold reads as "1:30" here
            // exactly as it did on the card you logged it from. The volume
            // half is dropped for a timed exercise: weight × reps is zero for
            // every held set, and "0 kg total" under a set of planks reads as
            // a bug rather than as an absence.
            topSet.seconds != null
                ? l10n.workoutSummaryTopSet(
                    formatLoggedSet(
                      weightKg: topSet.weight,
                      reps: topSet.reps,
                      seconds: topSet.seconds,
                      unit: unit,
                      l10n: l10n,
                    ),
                  )
                : l10n.workoutSummaryTopSetTotal(
                    formatLoggedSet(
                      weightKg: topSet.weight,
                      reps: topSet.reps,
                      seconds: null,
                      unit: unit,
                      l10n: l10n,
                    ),
                    formatWeightUnit(volume, unit, l10n: l10n),
                  ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The shared look of the three headline numbers.
///
/// Pulled out because two of them are now an [AnimatedCount], which needs the
/// style handed to it rather than inheriting the tile's, and having the third
/// drift out of step with them would be the sort of small wrongness nobody can
/// name but everybody sees.
TextStyle? _valueStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium;
