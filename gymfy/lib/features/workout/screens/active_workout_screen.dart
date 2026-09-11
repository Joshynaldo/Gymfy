import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/data/notification_service.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/exercise_thumbnail.dart';
import '../../exercises/screens/exercise_detail_screen.dart';
import '../../overload/data/overload_math.dart';
import '../../overload/data/overload_repository.dart';
import '../../plates/screens/plate_calculator_screen.dart';
import '../../../shared/widgets/weight_wheel.dart';
import '../../plates/widgets/plate_stacker.dart';
import '../../settings/data/notification_preferences.dart';
import '../data/rest_timer_controller.dart';
import '../data/rest_timer_repository.dart';
import '../data/session_repository.dart';
import '../data/workout_repository.dart';
import '../widgets/rest_timer_bar.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../app/theme/motion.dart';
import '../../../shared/widgets/fade_slide_in.dart';

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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: GlassAppBar(),
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
          return GlassScaffold(
            appBar: GlassAppBar(),
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
    final sets =
        ref.watch(sessionSetsProvider(session.id)).value ?? const <LoggedSet>[];

    // Group the logged sets by exercise so each card shows only its own sets.
    final setsByExercise = <String, List<LoggedSet>>{};
    for (final set in sets) {
      setsByExercise.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(session.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.donut_large_outlined),
            tooltip: 'Plate calculator',
            // Pushed over the session rather than routed to, so closing it
            // returns to the workout instead of leaving you in the More tab.
            onPressed: () => showPlateCalculator(context),
          ),
          TextButton(
            onPressed: () => _finish(context, ref),
            child: const Text('Finish'),
          ),
        ],
      ),
      // The rest timer is fixed at the top and must stay readable, so it is
      // held clear of the app bar; the exercise list below it slides under.
      body: Padding(
        padding: topBarInset(context),
        child: Column(
          children: [
            // Renders nothing unless a rest timer is running.
            const RestTimerBar(),
            Expanded(
              child: planned.isEmpty
                  ? const _EmptyState()
                  : ListView(
                      padding:
                          const EdgeInsets.fromLTRB(12, 12, 12, 32) +
                          bottomBarInset(context),
                      children: [
                        for (final p in planned)
                          _ExerciseLogCard(
                            session: session,
                            planned: p,
                            loggedSets:
                                setsByExercise[p.exercise.id] ?? const [],
                          ),
                      ],
                    ),
            ),
          ],
        ),
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

    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: ExerciseThumbnail(gifPath: exercise.gifPath),
            title: Text(exercise.name),
            subtitle: Text(
              'Target: ${formatSetTarget(entry.defaultSets, entry.defaultReps, entry.defaultRepsMax)}',
            ),
            trailing: _SuggestionChip(planned: planned),
            // Opens the same detail screen the library does — the animation,
            // the muscles worked, the rank. Mid-set is exactly when you want
            // to check a movement you're unsure of.
            //
            // Pushed rather than routed, for the same reason the plate
            // calculator is: `go` would switch to the Exercises tab and leave
            // you navigating back to your own session afterwards.
            onTap: () => showExerciseDetail(context, exercise.id),
          ),
          _LoggedSets(sets: loggedSets, accent: accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                // Offered first while the plan still expects warm-ups, and
                // quietly available afterwards — some days need a fourth.
                TextButton.icon(
                  onPressed: () => _addSet(context, ref, isWarmup: true),
                  icon: const Icon(Icons.local_fire_department_outlined),
                  label: Text(_warmupLabel),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _addSet(context, ref, isWarmup: false),
                  icon: const Icon(Icons.add),
                  label: const Text('Add set'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sets already logged in the phase [isWarmup] describes.
  List<LoggedSet> _phase({required bool isWarmup}) =>
      loggedSets.where((s) => s.isWarmup == isWarmup).toList();

  /// "Warm-up 2 of 3" while the plan still expects some, plain "Warm-up" after.
  String get _warmupLabel {
    final planned = this.planned.entry.warmupSets;
    final done = _phase(isWarmup: true).length;
    return done < planned ? 'Warm-up ${done + 1} of $planned' : 'Warm-up';
  }

  Future<void> _addSet(
    BuildContext context,
    WidgetRef ref, {
    required bool isWarmup,
  }) async {
    // Prefill from the last set logged *in this phase* — you are mid-ramp-up or
    // mid-working-set and almost certainly repeating that weight. Crossing the
    // divide is the one place it must not carry over: after three warm-ups,
    // offering 60 kg for your first working set would be worse than offering
    // nothing.
    final samePhase = _phase(isWarmup: isWarmup);
    final last = samePhase.isNotEmpty ? samePhase.last : null;

    // Warm-ups never take the overload suggestion: it is a target for the
    // working sets, and putting it on the bar for a ramp-up set would make the
    // ramp-up pointless. The suggestion is also only for the first working set,
    // because that is the moment the decision is actually being made.
    final suggestion = (isWarmup || last != null)
        ? null
        : ref
              .read(
                overloadSuggestionProvider((
                  entry: planned.entry,
                  exercise: planned.exercise,
                )),
              )
              .value;

    final result = await showDialog<({double weight, int reps})>(
      context: context,
      builder: (context) => _LogSetDialog(
        isWarmup: isWarmup,
        initialWeight: last?.weight ?? suggestion?.weight ?? 0,
        initialReps: last?.reps ?? planned.entry.defaultReps,
        unit: ref.read(weightUnitProvider),
        plateLoaded: planned.exercise.isPlateLoaded,
        exercise: planned.exercise,
        suggestion: suggestion,
      ),
    );
    if (result == null) return;

    await ref
        .read(sessionRepositoryProvider)
        .logSet(
          sessionId: session.id,
          exerciseId: planned.exercise.id,
          // Numbered within its own phase, so working sets read 1, 2, 3 however
          // long the ramp-up was.
          setNumber: samePhase.length + 1,
          weight: result.weight,
          reps: result.reps,
          isWarmup: isWarmup,
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
    await ref
        .read(restTimerProvider.notifier)
        .start(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          seconds: seconds,
        );
  }
}

/// The suggested next weight, on the exercise card.
///
/// Shown before you open the dialog so the decision is visible while you're
/// still deciding whether to take it — a number that only appears once you've
/// committed to logging is a number you can't think about.
///
/// Renders nothing when overload is off or there's no history yet.
class _SuggestionChip extends ConsumerWidget {
  const _SuggestionChip({required this.planned});

  final PlannedExercise planned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final unit = ref.watch(weightUnitProvider);
    final suggestion = ref
        .watch(
          overloadSuggestionProvider((
            entry: planned.entry,
            exercise: planned.exercise,
          )),
        )
        .value;

    if (suggestion == null) return const SizedBox.shrink();

    final (icon, colour) = switch (suggestion.reason) {
      OverloadReason.earned => (Icons.trending_up, accent),
      OverloadReason.deload => (
        Icons.trending_down,
        theme.colorScheme.onSurfaceVariant,
      ),
      _ => (Icons.remove, theme.colorScheme.onSurfaceVariant),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colour),
        const SizedBox(width: 4),
        Text(
          formatWeightUnit(suggestion.weight, unit),
          style: theme.textTheme.labelLarge?.copyWith(color: colour),
        ),
      ],
    );
  }
}

/// The sets logged so far, with a new one arriving rather than appearing.
///
/// Logging a set is the thing this app is for, and it happens perhaps forty
/// times a session with a phone propped against a rack. Before this, the row
/// simply existed on the next frame and the card jumped taller under it —
/// which is indistinguishable from a layout glitch, and gives you nothing to
/// confirm the tap landed except reading the numbers back.
///
/// Each row is keyed by its set id, so only the row that is genuinely new
/// animates. Keyed by position instead, adding a set would re-run the arrival
/// on every row beneath it and the card would ripple every time.
class _LoggedSets extends StatelessWidget {
  const _LoggedSets({required this.sets, required this.accent});

  final List<LoggedSet> sets;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: motionOf(context, AppDurations.standard),
      curve: AppCurves.settle,
      // Grows downward from the exercise's name rather than from its middle.
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final set in sets)
            FadeSlideIn(
              key: ValueKey(set.id),
              child: _LoggedSetRow(set: set, accent: accent),
            ),
        ],
      ),
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

    // Warm-ups are dimmed rather than hidden or restyled: they're still your
    // work, just not the part the numbers are about. Muted text plus the badge
    // makes the divide readable at arm's length without a heavy separator
    // cutting the card in two.
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 4, 2),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${set.setNumber}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: set.isWarmup ? muted : accent,
              ),
            ),
          ),
          if (set.isWarmup) ...[
            _WarmupBadge(colour: muted),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              '${formatWeightUnit(set.weight, unit)} × ${set.reps} reps',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: set.isWarmup ? muted : null,
              ),
            ),
          ),
          IconButton(
            // Re-tagging is the common repair: you ramp up, the bar feels
            // light, and what you called a warm-up was really your first
            // working set. Without this the only fix is deleting the row and
            // logging it again from memory.
            icon: Icon(
              set.isWarmup ? Icons.arrow_upward : Icons.local_fire_department,
            ),
            iconSize: 20,
            tooltip: set.isWarmup
                ? 'Make this a working set'
                : 'Make this a warm-up',
            onPressed: () => ref
                .read(sessionRepositoryProvider)
                .setWarmup(id: set.id, isWarmup: !set.isWarmup),
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

/// The small "W" that marks a ramp-up row.
class _WarmupBadge extends StatelessWidget {
  const _WarmupBadge({required this.colour});

  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'W',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colour),
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
    required this.isWarmup,
    required this.initialWeight,
    required this.initialReps,
    required this.unit,
    required this.plateLoaded,
    required this.suggestion,
    required this.exercise,
  });

  /// Whether this row is being logged as a ramp-up set. Only changes the title:
  /// the inputs are identical, because a warm-up is a real set.
  final bool isWarmup;

  /// In kilograms, as stored.
  final double initialWeight;
  final int initialReps;
  final WeightUnit unit;

  /// Why the weight is prefilled the way it is, when progressive overload had
  /// something to say. Null for the ordinary case.
  final OverloadSuggestion? suggestion;

  /// Whether this exercise is loaded with plates on a bar. When it is, the
  /// weight is built by tapping plates instead of typed — on a barbell you
  /// know what went on the bar, not what the total came to.
  final bool plateLoaded;

  /// The exercise being logged, so the plate stacker can use — and change —
  /// its own bar weight.
  final Exercise exercise;

  @override
  State<_LogSetDialog> createState() => _LogSetDialogState();
}

class _LogSetDialogState extends State<_LogSetDialog> {
  late final _repsController = TextEditingController(
    text: widget.initialReps.toString(),
  );

  /// The weight, in the *display* unit — one value whichever input is showing.
  ///
  /// Plates are physical objects labelled in one unit and the wheel offers that
  /// unit's steps, so neither input ever speaks kilograms. Conversion happens
  /// once, on save.
  late double _weight = weightIn(widget.initialWeight, widget.unit);

  /// Stacking stays optional on a barbell exercise — a fixed-weight bar, or a
  /// gym with plates the app doesn't know about, still has to be loggable.
  late bool _usePlates = widget.plateLoaded;

  @override
  void dispose() {
    _repsController.dispose();
    super.dispose();
  }

  void _submit() {
    final weight = weightToKilograms(_weight, widget.unit);
    final reps = int.tryParse(_repsController.text) ?? widget.initialReps;
    Navigator.of(
      context,
    ).pop((weight: weight < 0 ? 0.0 : weight, reps: reps < 0 ? 0 : reps));
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: Text(widget.isWarmup ? 'Log warm-up set' : 'Log set'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.suggestion != null) ...[
              _SuggestionNote(
                suggestion: widget.suggestion!,
                unit: widget.unit,
              ),
              const SizedBox(height: 12),
            ],
            if (_usePlates)
              PlateStacker(
                initialWeight: _weight,
                exerciseId: widget.exercise.id,
                onChanged: (weight) => _weight = weight,
              )
            else
              WeightWheel(
                // Keyed on the mode so switching inputs rebuilds the wheel at
                // the weight currently in hand, rather than reusing the drums'
                // old position.
                key: ValueKey(_usePlates),
                initialWeight: _weight,
                unit: widget.unit,
                onChanged: (weight) => _weight = weight,
              ),
            if (widget.plateLoaded)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _toggleInput,
                  icon: Icon(
                    _usePlates ? Icons.tune : Icons.donut_large_outlined,
                  ),
                  label: Text(_usePlates ? 'Pick a weight' : 'Stack plates'),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: const InputDecoration(labelText: 'Reps'),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
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

  /// Switches between stacking plates and picking a weight. Both write to the
  /// same `_weight`, so the number carries across untouched.
  void _toggleInput() => setState(() => _usePlates = !_usePlates);
}

/// One line saying where the prefilled weight came from.
///
/// A suggested number with no explanation is either obeyed blindly or ignored;
/// saying why makes it something you can agree or disagree with. And the weight
/// stays fully editable either way — the app proposes, it doesn't decide.
class _SuggestionNote extends StatelessWidget {
  const _SuggestionNote({required this.suggestion, required this.unit});

  final OverloadSuggestion suggestion;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, text) = switch (suggestion.reason) {
      OverloadReason.earned => (
        Icons.trending_up,
        'You hit every set last time — going up to '
            '${formatWeightUnit(suggestion.weight, unit)}.',
      ),
      OverloadReason.deload => (
        Icons.trending_down,
        'Several increases in a row. A lighter week at '
            '${formatWeightUnit(suggestion.weight, unit)} is suggested.',
      ),
      _ => (
        Icons.remove,
        'Same weight as last time — the rep target wasn\'t met yet.',
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
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
