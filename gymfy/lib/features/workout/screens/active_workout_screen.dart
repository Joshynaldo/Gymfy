import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../app/theme/glass.dart';
import '../../../app/theme/motion.dart';
import '../../../shared/data/notification_service.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../shared/widgets/pressable.dart';
import '../../exercises/screens/exercise_detail_screen.dart';
import '../../exercises/widgets/exercise_note.dart';
import '../../overload/data/overload_math.dart';
import '../../overload/data/overload_repository.dart';
import '../../plates/screens/plate_calculator_screen.dart';
import '../../settings/data/notification_preferences.dart';
import '../data/rest_timer_controller.dart';
import '../data/rest_timer_repository.dart';
import '../data/session_repository.dart';
import '../data/workout_repository.dart';
import '../widgets/log_set_sheet.dart';
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
            body: (context) => const Center(child: Text('Workout not found.')),
          );
        }
        return _ActiveWorkoutView(session: session);
      },
    );
  }
}

/// The screen while a workout is running.
///
/// One exercise at a time is a full card — the one you are on — and everything
/// else is a quiet row under "Up next". The arrangement this replaced gave
/// every exercise in the day an identical card with its own buttons: five
/// equally loud surfaces, four of them about something you were not doing.
/// Mid-set, with the phone propped against a rack, the screen has one job and
/// it is to show the set you are about to log.
///
/// Tapping a row moves the card to that exercise, so logging out of order — the
/// bench is busy, the rack is taken — is still one tap.
class _ActiveWorkoutView extends ConsumerStatefulWidget {
  const _ActiveWorkoutView({required this.session});

  final WorkoutSession session;

  @override
  ConsumerState<_ActiveWorkoutView> createState() => _ActiveWorkoutViewState();
}

class _ActiveWorkoutViewState extends ConsumerState<_ActiveWorkoutView> {
  /// The exercise you picked by hand, if you picked one.
  ///
  /// Held by id rather than by index: the day's plan can change underneath a
  /// running session, and an index would then point at a different movement.
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final dayId = session.dayId;
    final planned = dayId == null
        ? const <PlannedExercise>[]
        : (ref.watch(dayExercisesProvider(dayId)).value ??
              const <PlannedExercise>[]);
    final sets =
        ref.watch(sessionSetsProvider(session.id)).value ?? const <LoggedSet>[];

    // Group the logged sets by exercise so the card shows only its own.
    final setsByExercise = <String, List<LoggedSet>>{};
    for (final set in sets) {
      setsByExercise.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    // Watched as a boolean rather than as the timer itself: the timer ticks
    // once a second, and rebuilding this whole screen on every tick is exactly
    // the cost RestTimerBar exists to keep to itself.
    final resting = ref.watch(restTimerProvider.select((t) => t != null));

    final current = _current(planned, setsByExercise);

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
            onPressed: () => _finish(context),
            child: const Text('Finish'),
          ),
        ],
      ),
      body: (context) => planned.isEmpty
          ? const _EmptyState()
          : Stack(
              children: [
                ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 32) +
                      barInsets(context),
                  children: [
                    // The gap the rest pane floats in. It opens and closes with
                    // the pane rather than being permanent chrome, so a workout
                    // logged without the timer never pays for it.
                    AnimatedContainer(
                      duration: motionOf(context, AppDurations.standard),
                      curve: AppCurves.settle,
                      height: resting ? 124 : 0,
                    ),
                    if (current != null)
                      _CurrentExerciseCard(
                        key: ValueKey(current.exercise.id),
                        planned: current,
                        loggedSets:
                            setsByExercise[current.exercise.id] ?? const [],
                        onLog: (isWarmup) =>
                            _log(context, current, isWarmup: isWarmup),
                      ),
                    ..._upNext(planned, current, setsByExercise),
                  ],
                ),
                // Floating rather than in the flow: this is the one pane on the
                // screen with something genuinely passing underneath it, which
                // is what makes its blur worth the pass it costs.
                Positioned(
                  top: barInsets(context).top + 6,
                  left: 14,
                  right: 14,
                  child: const RestTimerBar(),
                ),
              ],
            ),
    );
  }

  /// The exercise the card is showing.
  ///
  /// Your pick if you made one, otherwise the first exercise still short of its
  /// planned working sets — which is where you are on any day you work through
  /// the plan in order.
  PlannedExercise? _current(
    List<PlannedExercise> planned,
    Map<String, List<LoggedSet>> setsByExercise,
  ) {
    if (planned.isEmpty) return null;
    if (_picked != null) {
      for (final entry in planned) {
        if (entry.exercise.id == _picked) return entry;
      }
    }
    for (final entry in planned) {
      final done = (setsByExercise[entry.exercise.id] ?? const [])
          .where((s) => !s.isWarmup)
          .length;
      if (done < entry.entry.defaultSets) return entry;
    }
    return planned.last;
  }

  List<Widget> _upNext(
    List<PlannedExercise> planned,
    PlannedExercise? current,
    Map<String, List<LoggedSet>> setsByExercise,
  ) {
    final rest = planned
        .where((p) => p.exercise.id != current?.exercise.id)
        .toList();
    if (rest.isEmpty) return const [];

    return [
      const SizedBox(height: 28),
      const _SectionLabel('UP NEXT'),
      const SizedBox(height: 12),
      for (final entry in rest)
        _UpNextRow(
          planned: entry,
          loggedSets: setsByExercise[entry.exercise.id] ?? const [],
          onTap: () => setState(() => _picked = entry.exercise.id),
        ),
    ];
  }

  Future<void> _log(
    BuildContext context,
    PlannedExercise planned, {
    required bool isWarmup,
  }) async {
    // Prefill from the last set logged *in this phase* — you are mid-ramp-up or
    // mid-working-set and almost certainly repeating that weight. Crossing the
    // divide is the one place it must not carry over: after three warm-ups,
    // offering 60 kg for your first working set would be worse than offering
    // nothing.
    final logged = ref.read(sessionSetsProvider(widget.session.id)).value ?? [];
    final samePhase = logged
        .where(
          (s) => s.exerciseId == planned.exercise.id && s.isWarmup == isWarmup,
        )
        .toList();
    final last = samePhase.isNotEmpty ? samePhase.last : null;

    // Warm-ups never take the overload suggestion: it is a target for the
    // working sets, and putting it on the bar for a ramp-up set would make the
    // ramp-up pointless. The suggestion is also only for the first working set,
    // because that is the moment the decision is actually being made.
    //
    // Awaited, not read off the current snapshot. `ref.read(...).value` on a
    // FutureProvider is whatever has resolved *so far*, so a suggestion still
    // in flight reads as no suggestion at all — the sheet then opens empty and
    // the increase you earned last week silently never appears. The window is
    // small but it is exactly the one the user is in: tap an exercise under Up
    // next, tap Log set, and the query for that exercise started one frame
    // ago. Awaiting costs a few milliseconds of a database read the screen is
    // already running anyway.
    final suggestion = (isWarmup || last != null)
        ? null
        : await ref.read(
            overloadSuggestionProvider((
              entry: planned.entry,
              exercise: planned.exercise,
            )).future,
          );
    if (!context.mounted) return;

    final result = await showLogSetSheet(
      context: context,
      exercise: planned.exercise,
      isWarmup: isWarmup,
      initialWeight: last?.weight ?? suggestion?.weight ?? 0,
      initialReps: last?.reps ?? planned.entry.defaultReps,
      unit: ref.read(weightUnitProvider),
      suggestion: suggestion,
      phaseLabel: isWarmup
          ? 'Warm-up ${samePhase.length + 1}'
          : 'Set ${samePhase.length + 1} · working set',
      repeatable: last,
    );
    if (result == null) return;

    // The sheet owns the warm-up decision from the moment it opens — you often
    // only know whether that was a ramp-up once the bar is in your hands — so
    // the set is numbered against whichever phase comes back, not the one the
    // button asked for.
    final phase = logged
        .where(
          (s) =>
              s.exerciseId == planned.exercise.id &&
              s.isWarmup == result.isWarmup,
        )
        .length;

    await ref
        .read(sessionRepositoryProvider)
        .logSet(
          sessionId: widget.session.id,
          exerciseId: planned.exercise.id,
          // Numbered within its own phase, so working sets read 1, 2, 3 however
          // long the ramp-up was.
          setNumber: phase + 1,
          weight: result.weight,
          reps: result.reps,
          isWarmup: result.isWarmup,
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

  Future<void> _finish(BuildContext context) async {
    // A rest timer outliving the workout it belongs to would be a puzzle, and
    // its notification would fire long after you've left the gym.
    ref.read(restTimerProvider.notifier).stop();
    await ref
        .read(sessionRepositoryProvider)
        .completeSession(widget.session.id);
    if (!context.mounted) return;
    context.go('/workout/summary/${widget.session.id}');
  }
}

/// The exercise you are on: its target, what overload has to say, the sets
/// logged so far, and the one button that matters.
class _CurrentExerciseCard extends ConsumerWidget {
  const _CurrentExerciseCard({
    super.key,
    required this.planned,
    required this.loggedSets,
    required this.onLog,
  });

  final PlannedExercise planned;
  final List<LoggedSet> loggedSets;

  /// Takes whether the ramp-up button was the one pressed. The sheet can still
  /// change its mind afterwards.
  final void Function(bool isWarmup) onLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final entry = planned.entry;
    final exercise = planned.exercise;
    final working = loggedSets.where((s) => !s.isWarmup).length;

    return AppPanel(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Pressable(
                  borderRadius: BorderRadius.circular(8),
                  splash: false,
                  // Opens the same detail screen the library does — the
                  // animation, the muscles worked, the rank. Mid-set is exactly
                  // when you want to check a movement you are unsure of.
                  //
                  // Pushed rather than routed, for the same reason the plate
                  // calculator is: `go` would switch tabs and leave you
                  // navigating back to your own session afterwards.
                  onTap: () => showExerciseDetail(context, exercise.id),
                  child: Text(
                    exercise.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatSetTarget(
                  entry.defaultSets,
                  entry.defaultReps,
                  entry.defaultRepsMax,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          _SuggestionLine(planned: planned),
          // The reason the feature exists. A seat height is worth nothing in a
          // library you have to go and find — it is worth something in the
          // eight seconds you are standing at the machine deciding where to
          // put the pin. On the current card only: one row here is useful, a
          // row on all six exercises is a list of placeholders.
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ExerciseNoteTile(exercise: exercise, dense: true),
          ),
          _LoggedSets(sets: loggedSets, accent: accent),
          const SizedBox(height: 14),
          Row(
            children: [
              // Offered first while the plan still expects warm-ups, and
              // quietly available afterwards — some days need a fourth.
              _WarmupButton(
                planned: planned,
                loggedSets: loggedSets,
                onPressed: () => onLog(true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Log set ${working + 1}',
                  icon: Icons.add,
                  // Deliberately not the accent. On this screen the accent
                  // belongs to the rest countdown, which is the thing you read
                  // from across a gym; a second accent surface here would make
                  // you check which of the two was shouting.
                  kind: AppButtonKind.secondary,
                  onPressed: () => onLog(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One exercise still to come: its target, and a dot per planned set.
///
/// The dots are the whole reason this row can be quiet. They say how far into
/// the exercise you are without a number having to be read, which is all you
/// need from something you are not doing yet.
class _UpNextRow extends StatelessWidget {
  const _UpNextRow({
    required this.planned,
    required this.loggedSets,
    required this.onTap,
  });

  final PlannedExercise planned;
  final List<LoggedSet> loggedSets;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = planned.entry;
    final done = loggedSets.where((s) => !s.isWarmup).length;

    return AppCard(
      tier: GlassTier.quiet,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planned.exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  formatSetTarget(
                    entry.defaultSets,
                    entry.defaultReps,
                    entry.defaultRepsMax,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _SetDots(total: entry.defaultSets, done: done),
        ],
      ),
    );
  }
}

/// One dot per planned set, filled as they are logged.
class _SetDots extends StatelessWidget {
  const _SetDots({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(left: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.onSurface.withValues(
                alpha: i < done ? 0.62 : 0.22,
              ),
            ),
          ),
      ],
    );
  }
}

/// A caps heading over a run of rows.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// "Warm-up 2 of 3" while the plan still expects some, plain "Warm-up" after.
class _WarmupButton extends StatelessWidget {
  const _WarmupButton({
    required this.planned,
    required this.loggedSets,
    required this.onPressed,
  });

  final PlannedExercise planned;
  final List<LoggedSet> loggedSets;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expected = planned.entry.warmupSets;
    final done = loggedSets.where((s) => s.isWarmup).length;
    final label = done < expected
        ? 'Warm-up ${done + 1} of $expected'
        : 'Warm-up';
    final radius = BorderRadius.circular(16);

    return Pressable(
      borderRadius: radius,
      onTap: onPressed,
      splash: false,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: radius,
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// What progressive overload has to say about the next set, on the card.
///
/// Shown before you open the sheet so the decision is visible while you are
/// still deciding whether to take it — a number that only appears once you have
/// committed to logging is a number you cannot think about.
///
/// Renders nothing when overload is off or there is no history yet.
class _SuggestionLine extends ConsumerWidget {
  const _SuggestionLine({required this.planned});

  final PlannedExercise planned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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

    final weight = formatWeightUnit(suggestion.weight, unit);
    final (icon, text) = switch (suggestion.reason) {
      OverloadReason.earned => (
        Icons.trending_up,
        'You hit every set last time — going up to $weight',
      ),
      OverloadReason.deload => (
        Icons.trending_down,
        'Several increases in a row — a lighter $weight is suggested',
      ),
      _ => (Icons.remove, 'Same $weight as last time'),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
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
          if (sets.isNotEmpty) const SizedBox(height: 12),
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

    return SizedBox(
      height: 36,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '${set.setNumber}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: set.isWarmup ? muted : accent,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${formatWeightUnit(set.weight, unit)} × ${set.reps} reps',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: set.isWarmup ? muted : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (set.isWarmup) ...[
            _WarmupBadge(colour: muted),
            const SizedBox(width: 4),
          ],
          IconButton(
            // Re-tagging is the common repair: you ramp up, the bar feels
            // light, and what you called a warm-up was really your first
            // working set. Without this the only fix is deleting the row and
            // logging it again from memory.
            icon: Icon(
              set.isWarmup ? Icons.arrow_upward : Icons.local_fire_department,
            ),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: set.isWarmup
                ? 'Make this a working set'
                : 'Make this a warm-up',
            onPressed: () => ref
                .read(sessionRepositoryProvider)
                .setWarmup(id: set.id, isWarmup: !set.isWarmup),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
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
