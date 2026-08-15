import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/data/notification_service.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/exercise_display.dart';
import '../../../shared/utils/units.dart';
import '../../settings/data/notification_preferences.dart';
import '../data/rest_timer_controller.dart';
import '../data/rest_timer_repository.dart';
import '../data/session_repository.dart';
import '../data/workout_repository.dart';
import '../widgets/rest_timer_bar.dart';

/// The live workout screen: log sets exercise by exercise while you train.
///
/// The exercise list comes from the session's planned day (so you see your
/// targets), while the sets you log are saved against the session itself.
class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider(sessionId));

    return sessionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load this workout.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (session) {
        if (session == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Workout not found.')),
          );
        }
        return _ActiveWorkoutView(session: session);
      },
    );
  }
}

class _ActiveWorkoutView extends ConsumerWidget {
  const _ActiveWorkoutView({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayId = session.dayId;
    final planned = dayId == null
        ? const <PlannedExercise>[]
        : (ref.watch(dayExercisesProvider(dayId)).value ??
              const <PlannedExercise>[]);
    final sets = ref.watch(sessionSetsProvider(session.id)).value ??
        const <LoggedSet>[];

    // Group the logged sets by exercise so each card shows only its own sets.
    final setsByExercise = <String, List<LoggedSet>>{};
    for (final set in sets) {
      setsByExercise.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(session.name),
        actions: [
          TextButton(
            onPressed: () => _finish(context, ref),
            child: const Text('Finish'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Renders nothing unless a rest timer is running.
          const RestTimerBar(),
          Expanded(
            child: planned.isEmpty
                ? const _EmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                    children: [
                      for (final p in planned)
                        _ExerciseLogCard(
                          session: session,
                          planned: p,
                          loggedSets: setsByExercise[p.exercise.id] ?? const [],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    // A rest timer outliving the workout it belongs to would be a puzzle, and
    // its notification would fire long after you've left the gym.
    ref.read(restTimerProvider.notifier).stop();
    await ref.read(sessionRepositoryProvider).completeSession(session.id);
    if (!context.mounted) return;
    context.go('/workout/summary/${session.id}');
  }
}

/// One exercise while training: its planned target, the sets logged so far,
/// and a button to log another set.
class _ExerciseLogCard extends ConsumerWidget {
  const _ExerciseLogCard({
    required this.session,
    required this.planned,
    required this.loggedSets,
  });

  final WorkoutSession session;
  final PlannedExercise planned;
  final List<LoggedSet> loggedSets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final entry = planned.entry;
    final exercise = planned.exercise;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Icon(categoryIcon(exercise.category), color: accent),
            ),
            title: Text(exercise.name),
            subtitle: Text(
              'Target: ${entry.defaultSets} × ${entry.defaultReps}',
            ),
          ),
          for (final set in loggedSets)
            _LoggedSetRow(set: set, accent: accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addSet(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add set'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSet(BuildContext context, WidgetRef ref) async {
    // Prefill from the last logged set if there is one, otherwise from the
    // planned rep target — this makes logging the next set a couple of taps.
    final last = loggedSets.isNotEmpty ? loggedSets.last : null;
    final result = await showDialog<({double weight, int reps})>(
      context: context,
      builder: (context) => _LogSetDialog(
        initialWeight: last?.weight ?? 0,
        initialReps: last?.reps ?? planned.entry.defaultReps,
        unit: ref.read(weightUnitProvider),
      ),
    );
    if (result == null) return;

    await ref.read(sessionRepositoryProvider).logSet(
      sessionId: session.id,
      exerciseId: planned.exercise.id,
      setNumber: loggedSets.length + 1,
      weight: result.weight,
      reps: result.reps,
    );

    // Logging a set is exactly when rest starts, so the timer needs no button
    // of its own — one less thing to do between sets.
    final exercise = planned.exercise;
    final seconds = ref.read(restForExerciseProvider(exercise.id));
    if (ref.read(restTimerAlertsProvider).value ?? true) {
      // Asked here rather than at launch: the permission dialog makes sense in
      // the moment it's needed, and a user who never rests is never asked.
      await ref.read(notificationServiceProvider).requestPermission();
    }
    await ref.read(restTimerProvider.notifier).start(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      seconds: seconds,
    );
  }
}

class _LoggedSetRow extends ConsumerWidget {
  const _LoggedSetRow({required this.set, required this.accent});

  final LoggedSet set;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 4, 2),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${set.setNumber}',
              style: theme.textTheme.labelLarge?.copyWith(color: accent),
            ),
          ),
          Expanded(
            child: Text(
              '${formatWeightUnit(set.weight, unit)} × ${set.reps} reps',
              style: theme.textTheme.bodyLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 20,
            tooltip: 'Delete set',
            onPressed: () =>
                ref.read(sessionRepositoryProvider).deleteSet(set.id),
          ),
        ],
      ),
    );
  }
}

/// Dialog to enter the weight and reps for a set. Owns its controllers via a
/// [StatefulWidget] so they're disposed at the right time.
///
/// Talks to the user in [unit] but takes and returns kilograms, so the rest of
/// the screen never has to think about which unit is on screen.
class _LogSetDialog extends StatefulWidget {
  const _LogSetDialog({
    required this.initialWeight,
    required this.initialReps,
    required this.unit,
  });

  /// In kilograms, as stored.
  final double initialWeight;
  final int initialReps;
  final WeightUnit unit;

  @override
  State<_LogSetDialog> createState() => _LogSetDialogState();
}

class _LogSetDialogState extends State<_LogSetDialog> {
  late final _weightController = TextEditingController(
    text: formatWeightIn(widget.initialWeight, widget.unit),
  );
  late final _repsController =
      TextEditingController(text: widget.initialReps.toString());

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _submit() {
    // Unparseable text keeps the weight it started with rather than logging a
    // zero — a fat-fingered edit shouldn't quietly wipe out the set.
    final weight =
        parseWeightAsKilograms(_weightController.text, widget.unit) ??
        widget.initialWeight;
    final reps = int.tryParse(_repsController.text) ?? widget.initialReps;
    Navigator.of(context).pop((
      weight: weight < 0 ? 0.0 : weight,
      reps: reps < 0 ? 0 : reps,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log set'),
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _weightController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Weight',
                suffixText: widget.unit.label,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: const InputDecoration(labelText: 'Reps'),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Icons.fitness_center,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('Nothing to log', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'This day has no exercises. Add some to its plan first, then '
              'start the workout again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
