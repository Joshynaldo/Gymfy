import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/animated_count.dart';
import '../../../shared/utils/units.dart';
import '../../exercises/data/exercise_repository.dart';
import '../../muscle_map/data/muscle_volume_repository.dart';
import '../../muscle_map/widgets/muscle_map_view.dart';
import '../data/session_repository.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';

/// Shown after finishing a workout: a recap of the session just completed —
/// duration, total sets, total volume, and a per-exercise breakdown.
///
/// Reachable via `/workout/summary/:sessionId`, so tapping the system back
/// button returns to the Workout tab home rather than the live logging screen.
class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider(sessionId));

    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Workout complete'),
        automaticallyImplyLeading: false,
      ),
      body: (context) => sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load the summary.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Workout not found.'));
          }
          return _SummaryBody(session: session);
        },
      ),
    );
  }
}

class _SummaryBody extends ConsumerWidget {
  const _SummaryBody({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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

    final completedAt = session.completedAt ?? session.startedAt;
    final duration = completedAt.difference(session.startedAt);

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
              formatDateTime(session.startedAt),
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
        if (sets.isEmpty)
          Text(
            'No sets were logged in this workout.',
            style: theme.textTheme.bodyMedium,
          )
        else ...[
          Text('Exercises', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in byExercise.entries)
            _ExerciseSummaryTile(
              name: nameById[entry.key] ?? entry.key,
              sets: entry.value,
            ),
          const SizedBox(height: 24),
          Text('Muscles worked', style: theme.textTheme.titleMedium),
          SizedBox(
            height: 440,
            child: MuscleMapView(
              intensities: ref.watch(
                sessionMuscleIntensitiesProvider(session.id),
              ),
              emptyMessage: 'No muscles to show for this workout.',
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.go('/workout'),
          child: const Text('Done'),
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

  final Duration duration;
  final int setCount;

  /// In kilograms, as stored.
  final double totalVolume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(weightUnitProvider);

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.timer_outlined,
            label: 'Duration',
            // Not counted up: a clock that races from 00:00 to your session
            // length looks like the timer is still running.
            value: Text(formatDuration(duration), style: _valueStyle(context)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.repeat,
            label: 'Sets',
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
            icon: Icons.fitness_center,
            label: 'Volume',
            value: AnimatedCount(
              value: totalVolume,
              from: 0,
              format: (value) => formatWeightUnit(value, unit),
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
    final unit = ref.watch(weightUnitProvider);
    final volume = sets.fold<double>(0, (sum, s) => sum + s.weight * s.reps);
    // The "top set" is the heaviest; ties broken by the most reps.
    final topSet = sets.reduce((a, b) {
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
                '${sets.length} ${sets.length == 1 ? 'set' : 'sets'}',
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
                ? 'Top set ${formatLoggedSet(weightKg: topSet.weight, reps: topSet.reps, seconds: topSet.seconds, unit: unit)}'
                : 'Top set ${formatLoggedSet(weightKg: topSet.weight, reps: topSet.reps, seconds: null, unit: unit)}'
                      '  •  ${formatWeightUnit(volume, unit)} total',
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
