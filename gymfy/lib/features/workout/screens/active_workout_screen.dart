import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../app/theme/glass.dart';
import '../../../app/theme/motion.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/data/notification_service.dart';
import '../../../shared/data/settings_repository.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_picker.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../shared/widgets/pressable.dart';
import '../../exercises/screens/exercise_detail_screen.dart';
import '../../exercises/widgets/exercise_note.dart';
import '../../overload/data/overload_math.dart';
import '../../overload/data/overload_repository.dart';
import '../../overload/data/percent_target.dart' show formatPercent;
import '../../plates/data/plate_math.dart';
import '../../plates/screens/plate_calculator_screen.dart';
import '../../settings/data/notification_preferences.dart';
import '../../workout_notification/data/workout_notification.dart';
import '../data/logging_preferences.dart';
import '../data/next_set.dart';
import '../data/personal_records.dart';
import '../data/rest_timer_controller.dart';
import '../data/rest_timer_repository.dart';
import '../data/session_repository.dart';
import '../data/supersets.dart';
import '../widgets/log_set_sheet.dart';
import '../widgets/record_celebration.dart';
import '../widgets/rest_timer_bar.dart';
import '../widgets/session_exercise_actions.dart';
import '../widgets/warmup_calculator_sheet.dart';
import '../../../shared/widgets/lucide_icons.dart';

/// The live workout screen: log sets exercise by exercise while you train.
///
/// The exercise list is the session's own running order — copied from the
/// planned day when it started (so you see your targets), empty for a free
/// workout, and editable as you go — while the sets you log are saved against
/// the session itself.
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
              context.l10n.workoutLoadFailed('$error'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (session) {
        if (session == null) {
          return GlassScaffold(
            appBar: GlassAppBar(),
            body: (context) =>
                Center(child: Text(context.l10n.workoutNotFound)),
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
  /// The record being celebrated, if a set just beat one. See [_celebrate].
  ({String exerciseName, List<BrokenRecord> records})? _celebration;
  Timer? _celebrationTimer;

  @override
  void initState() {
    super.initState();
    // After the first frame, so the system dialog does not open over a
    // screen that has not drawn yet.
    WidgetsBinding.instance.addPostFrameCallback((_) => _askForNotifications());
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    super.dispose();
  }

  /// Asks for notification permission for the ongoing workout notification.
  ///
  /// Here, when a workout starts or is resumed, because that is the moment
  /// the notification is for — the same reasoning that has the rest timer
  /// ask when the first rest starts rather than at launch. Android asks at
  /// most twice and then stops showing the dialog by itself, and on older
  /// versions this answers yes without asking.
  Future<void> _askForNotifications() async {
    // Not on iOS, which has no workout notification to ask for: it would
    // be a permission dialog for nothing.
    if (!WorkoutNotificationBridge.supported) return;
    final bool wanted;
    try {
      wanted = await _readSetting(workoutNotificationProvider);
    } on StateError {
      // The screen closed before the setting loaded. Nothing to ask for.
      return;
    }
    if (!wanted || !mounted) return;
    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermission();
    // Everything posted before the answer was dropped for want of
    // permission, and nothing has changed since to post it again.
    if (granted && mounted) {
      ref.read(workoutNotificationSyncProvider.notifier).resend();
    }
  }

  /// Puts the card on [exerciseId], or back on the plan's own choice for
  /// null. Shared with the notification and the watch — see
  /// [PickedExercise].
  void _pick(String? exerciseId) {
    if (!mounted) return;
    ref
        .read(pickedExerciseProvider(widget.session.id).notifier)
        .pick(exerciseId);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final entriesAsync = ref.watch(sessionExercisesProvider(session.id));
    final planned = entriesAsync.value ?? const <SessionExerciseEntry>[];
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

    final current = currentSessionEntry(
      planned,
      sets,
      picked: ref.watch(pickedExerciseProvider(session.id)),
    );

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(session.name),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.chartPie),
            tooltip: context.l10n.platesTitle,
            // Pushed over the session rather than routed to, so closing it
            // returns to the workout instead of leaving you in the More tab.
            onPressed: () => showPlateCalculator(context),
          ),
          TextButton(
            onPressed: () => _finish(context),
            child: Text(context.l10n.workoutFinish),
          ),
        ],
      ),
      body: (context) => planned.isEmpty
          // Nothing until the list has loaded, rather than flashing the empty
          // state at a workout that has exercises.
          ? (entriesAsync.hasValue
                ? _EmptyState(
                    isFree: session.dayId == null,
                    onAdd: () => _addExercises(context, planned),
                  )
                : const SizedBox.shrink())
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
                        supersetPartners: _partnersOf(planned, current),
                        loggedSets:
                            setsByExercise[current.exercise.id] ?? const [],
                        onLog: (type) => _log(context, current, type: type),
                        onWarmupCalculator: () =>
                            _openWarmupCalculator(context, current),
                        onMore: () => _exerciseActions(
                          context,
                          current,
                          planned,
                          hasSets: setsByExercise.containsKey(
                            current.exercise.id,
                          ),
                        ),
                      ),
                    ..._upNext(planned, current, setsByExercise),
                    const SizedBox(height: 16),
                    // At the foot of the list, where you look once the plan
                    // runs out — and the only control a free workout starts
                    // with, so it has to be findable without a menu.
                    AppButton(
                      label: context.l10n.workoutAddExercise,
                      icon: LucideIcons.plus,
                      kind: AppButtonKind.secondary,
                      onPressed: () => _addExercises(context, planned),
                    ),
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
                if (_celebration case final celebration?)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: barInsets(context).bottom + 16,
                    child: RecordCelebration(
                      // Keyed by the records, so a second record straight
                      // after the first springs in again instead of silently
                      // swapping its text.
                      key: ObjectKey(celebration),
                      exerciseName: celebration.exerciseName,
                      records: celebration.records,
                      onDismiss: _dismissCelebration,
                    ),
                  ),
              ],
            ),
    );
  }

  /// Puts a new record on screen for a few seconds, with a heavy buzz.
  ///
  /// The haptic is the part that reaches you: the phone is usually propped on
  /// a bench while you rack the bar, and a pane nobody looks at celebrates
  /// nothing. Haptics are not motion, so they fire with reduced motion on too;
  /// the pane itself honours the setting (see [RecordCelebration]).
  void _celebrate(String exerciseName, List<BrokenRecord> records) {
    HapticFeedback.heavyImpact();
    _celebrationTimer?.cancel();
    setState(
      () => _celebration = (exerciseName: exerciseName, records: records),
    );
    _celebrationTimer = Timer(const Duration(seconds: 5), _dismissCelebration);
  }

  void _dismissCelebration() {
    _celebrationTimer?.cancel();
    if (mounted && _celebration != null) {
      setState(() => _celebration = null);
    }
  }

  /// The other exercises in [entry]'s superset, in order. Empty when it
  /// stands alone.
  static List<SessionExerciseEntry> _partnersOf(
    List<SessionExerciseEntry> planned,
    SessionExerciseEntry entry,
  ) {
    for (final block in supersetBlocks(planned, (e) => e.supersetGroup)) {
      if (block.contains(entry)) {
        return [
          for (final e in block)
            if (e != entry) e,
        ];
      }
    }
    return const [];
  }

  /// Everything but the card, in running order. A superset's members are
  /// drawn as one group, so you can see what is done back to back before you
  /// get there.
  List<Widget> _upNext(
    List<SessionExerciseEntry> planned,
    SessionExerciseEntry? current,
    Map<String, List<LoggedSet>> setsByExercise,
  ) {
    if (planned.length < 2) return const [];

    Widget row(SessionExerciseEntry entry) => _UpNextRow(
      planned: entry,
      loggedSets: setsByExercise[entry.exercise.id] ?? const [],
      onTap: () => _pick(entry.exercise.id),
    );

    // One block's rows, minus whatever is on the card. A superset keeps its
    // grouping even with one member showing, so it still reads as "next, and
    // straight after the card".
    List<Widget> rows(List<SessionExerciseEntry> block) {
      final rest = [
        for (final e in block)
          if (e != current) e,
      ];
      if (rest.isEmpty) return const [];
      if (block.length == 1) return [row(rest.single)];
      return [
        _SupersetGroup(children: [for (final e in rest) row(e)]),
      ];
    }

    return [
      const SizedBox(height: 28),
      Row(
        children: [
          Expanded(child: _SectionLabel(context.l10n.workoutUpNext)),
          // Beside the list it changes. Tucked behind a menu it would be
          // undiscoverable; in the app bar it would crowd Finish.
          TextButton.icon(
            onPressed: () => reorderSessionExercises(
              context,
              ref,
              sessionId: widget.session.id,
              entries: planned,
            ),
            icon: const Icon(LucideIcons.arrowUpDown, size: 18),
            label: Text(context.l10n.workoutReorder),
          ),
        ],
      ),
      const SizedBox(height: 4),
      for (final block in supersetBlocks(planned, (e) => e.supersetGroup))
        ...rows(block),
    ];
  }

  /// Adds exercises from the picker, and puts the card on the first of them
  /// when the workout had none to be on.
  Future<void> _addExercises(
    BuildContext context,
    List<SessionExerciseEntry> entries,
  ) async {
    final added = await addExercisesToSession(
      context,
      ref,
      sessionId: widget.session.id,
      entries: entries,
    );
    if (added.isNotEmpty && entries.isEmpty) _pick(added.first);
  }

  /// The menu on the card: swap the exercise, pair it into a superset, or
  /// take it out of today's list.
  Future<void> _exerciseActions(
    BuildContext context,
    SessionExerciseEntry entry,
    List<SessionExerciseEntry> entries, {
    required bool hasSets,
  }) async {
    final action = await showOptionPicker<_EntryAction>(
      context: context,
      title: entry.exercise.name,
      options: [
        (
          value: _EntryAction.swap,
          label: context.l10n.workoutSwapExercise,
          subtitle: context.l10n.workoutSwapExerciseSubtitle,
        ),
        // Hidden with nothing to pair it with.
        if (entries.length > 1)
          (
            value: _EntryAction.superset,
            label: context.l10n.workoutSuperset,
            subtitle: context.l10n.workoutSupersetActionSubtitle,
          ),
        // Only offered while nothing is logged for it: the sets you did are
        // removed with the delete button on each row, not by a list edit.
        if (!hasSets)
          (
            value: _EntryAction.remove,
            label: context.l10n.workoutRemoveFromWorkout,
            subtitle: context.l10n.workoutPlanUnchanged,
          ),
      ],
      selected: null,
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _EntryAction.swap:
        final swapped = await swapSessionExercise(
          context,
          ref,
          entry: entry,
          entries: entries,
        );
        if (swapped != null) _pick(swapped);
      case _EntryAction.superset:
        await editSessionSuperset(context, ref, entry: entry, entries: entries);
      case _EntryAction.remove:
        await ref.read(sessionRepositoryProvider).removeExercise(entry.row.id);
        if (mounted &&
            ref.read(pickedExerciseProvider(widget.session.id)) ==
                entry.exercise.id) {
          _pick(null);
        }
    }
  }

  /// Moves the card after a working set of [entry] in a superset, and says
  /// whether the rest timer should start — see [supersetStepAfter] for the
  /// rules. A standalone exercise rests and leaves the card alone.
  ///
  /// [workingDone] counts the working sets logged per exercise, the set just
  /// saved included. It is passed in rather than read from the sets stream,
  /// which may not have caught up with that set yet.
  bool _advanceSuperset(
    SessionExerciseEntry entry, {
    required Map<String, int> workingDone,
  }) {
    final entries =
        ref.read(sessionExercisesProvider(widget.session.id)).value ??
        const <SessionExerciseEntry>[];
    final step = supersetStepAfter(
      entries,
      // The same entry from the current list: blocks match by identity, and
      // the list may have been re-read since the card was built.
      entries.firstWhere((e) => e.row.id == entry.row.id, orElse: () => entry),
      (e) => e.supersetGroup,
      hasSetsLeft: (e) =>
          (workingDone[e.exercise.id] ?? 0) < e.targets.defaultSets,
    );
    if (step == null) return true;
    _pick(step.next?.exercise.id);
    return step.rests;
  }

  Future<void> _log(
    BuildContext context,
    SessionExerciseEntry planned, {
    required SetType type,
  }) async {
    final isWarmup = type.isWarmupPhase;
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
              entry: planned.targets,
              exercise: planned.exercise,
            )).future,
          );
    // Awaited for the same reason: read cold, the setting would answer "off"
    // until its row loaded, and the first set would go unrated.
    final effortMode = await _readSetting(effortRatingModeProvider);
    if (!context.mounted) return;
    final l10n = context.l10n;

    final result = await showLogSetSheet(
      context: context,
      exercise: planned.exercise,
      setType: type,
      initialWeight: last?.weight ?? suggestion?.weight ?? 0,
      initialReps: last?.reps ?? planned.targets.defaultReps,
      unit: ref.read(weightUnitProvider),
      suggestion: suggestion,
      phaseLabel: isWarmup
          ? l10n.workoutPhaseWarmup(samePhase.length + 1)
          : l10n.workoutPhaseWorking(samePhase.length + 1),
      repeatable: last,
      effortMode: effortMode,
    );
    if (result == null) return;

    // The sheet owns the set-type decision from the moment it opens — you
    // often only know whether that was a ramp-up once the bar is in your
    // hands — so the set is numbered against whichever phase comes back, not
    // the one the button asked for.
    final phase = logged
        .where(
          (s) =>
              s.exerciseId == planned.exercise.id &&
              s.isWarmup == result.setType.isWarmupPhase,
        )
        .length;

    // The bests to beat, read *before* the set is written so the new set is
    // never measured against itself.
    final records = ref.read(personalRecordsRepositoryProvider);
    final before = result.setType.countsTowardStrength
        ? await records.baselineFor(
            planned.exercise.id,
            sessionId: widget.session.id,
          )
        : null;

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
          setType: result.setType,
          seconds: result.seconds,
          rpe: result.rpe,
          rir: result.rir,
        );

    if (before != null) {
      final broken = recordsSetBy(
        type: result.setType,
        weightKg: result.weight,
        reps: result.reps,
        seconds: result.seconds,
        before: before,
      );
      if (broken.isNotEmpty && mounted) {
        _celebrate(planned.exercise.name, broken);
      }
    }

    // Mid-superset there is no rest: you go straight to the next exercise of
    // the group that still has sets to do, so the card moves there instead.
    // The rest comes once nobody later in the group is left, and the card goes
    // back to the top of the group for the next round.
    //
    // Only for working sets. A warm-up ramps one exercise up on its own before
    // the rounds start, so it rests like any standalone set and the card stays
    // put for the next ramp-up.
    if (!result.setType.isWarmupPhase) {
      // `logged` was read before the sheet opened, so it is everything but
      // the set just saved — counted in here by hand.
      final workingDone = <String, int>{planned.exercise.id: 1};
      for (final set in logged) {
        if (set.isWarmup) continue;
        workingDone[set.exerciseId] = (workingDone[set.exerciseId] ?? 0) + 1;
      }
      final rests = _advanceSuperset(planned, workingDone: workingDone);
      if (!rests) return;
    }

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

  /// Opens the warm-up calculator and logs the ramp sets it returns.
  ///
  /// The working weight it starts from is the best guess available, in order:
  /// a working set already logged today, what overload suggests, the top
  /// weight of the last session, or nothing (the sheet then asks for one).
  Future<void> _openWarmupCalculator(
    BuildContext context,
    SessionExerciseEntry planned,
  ) async {
    final exercise = planned.exercise;
    final logged = ref.read(sessionSetsProvider(widget.session.id)).value ?? [];
    final todays = logged
        .where((s) => s.exerciseId == exercise.id && isWorkingSet(s))
        .toList();

    double working = todays.isEmpty ? 0 : topWeight(todays) ?? 0;
    if (working <= 0) {
      final suggestion = await ref.read(
        overloadSuggestionProvider((
          entry: planned.targets,
          exercise: exercise,
        )).future,
      );
      working = suggestion?.weight ?? 0;
    }
    if (working <= 0) {
      final history = await ref
          .read(overloadRepositoryProvider)
          .recentSessions(exercise.id, limit: 1);
      working = history.isEmpty ? 0 : topWeight(history.first) ?? 0;
    }

    // The ramp, the plates and the bar are all settings this screen may never
    // have watched. Wait for their rows, so a customised inventory is not
    // quietly replaced by the default one for the first warm-up of the day.
    final unit = ref.read(weightUnitProvider);
    final kg = unit == WeightUnit.kg;
    final ramp = await _readSetting(warmupRampProvider);
    await _readSetting(
      rawSettingProvider(kg ? platesKgSetting : platesLbsSetting),
    );
    await _readSetting(rawSettingProvider(kg ? barKgSetting : barLbsSetting));
    if (!context.mounted) return;

    final steps = await showWarmupCalculator(
      context: context,
      exercise: exercise,
      workingKg: working,
      unit: unit,
      ramp: ramp,
      plates: ref.read(availablePlatesProvider),
      bar: barForExercise(
        exercise.barWeightKg,
        ref.read(barWeightProvider),
        unit,
      ),
    );
    if (steps == null || steps.isEmpty) return;

    // Numbered on from whatever warm-ups are already logged, in the warm-up
    // phase, so the working sets keep reading 1, 2, 3.
    final current =
        ref.read(sessionSetsProvider(widget.session.id)).value ?? logged;
    var number = current
        .where((s) => s.exerciseId == exercise.id && s.isWarmup)
        .length;
    final sessions = ref.read(sessionRepositoryProvider);
    for (final step in steps) {
      await sessions.logSet(
        sessionId: widget.session.id,
        exerciseId: exercise.id,
        setNumber: ++number,
        weight: step.weightKg,
        reps: step.reps,
        setType: SetType.warmup,
      );
    }
  }

  /// The first value of a settings stream, listening while it waits.
  ///
  /// A bare `ref.read(provider.future)` is not enough for a setting nothing
  /// on screen watches: a provider with no listener is paused, so its stream
  /// never delivers and the read never completes. Listening for the length of
  /// the wait keeps it running without keeping it alive afterwards.
  Future<T> _readSetting<T>(StreamProvider<T> provider) async {
    final subscription = ref.listenManual(provider, (_, _) {});
    try {
      return await ref.read(provider.future);
    } finally {
      subscription.close();
    }
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
    required this.supersetPartners,
    required this.loggedSets,
    required this.onLog,
    required this.onWarmupCalculator,
    required this.onMore,
  });

  final SessionExerciseEntry planned;

  /// The rest of its superset, in order; empty when it stands alone.
  final List<SessionExerciseEntry> supersetPartners;

  final List<LoggedSet> loggedSets;

  /// Takes the set type the pressed button starts the sheet on. The sheet can
  /// still change its mind afterwards.
  final void Function(SetType type) onLog;

  /// Opens the ramp calculator for this exercise.
  final VoidCallback onWarmupCalculator;

  /// Opens the swap / remove menu.
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final entry = planned.targets;
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
              // Swap and remove: things you do to the list, not to a set, so
              // they sit behind one quiet button rather than beside Log set.
              SizedBox(
                width: 32,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  icon: const Icon(LucideIcons.ellipsisVertical),
                  tooltip: context.l10n.workoutExerciseOptionsTooltip,
                  onPressed: onMore,
                ),
              ),
            ],
          ),
          if (supersetPartners.isNotEmpty)
            _SupersetLine(partners: supersetPartners, accent: accent),
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
                onPressed: () => onLog(SetType.warmup),
              ),
              // Next to the warm-up button it fills in for. Not offered on a
              // hold: a ramp is weight climbing towards a working weight, and
              // a plank has neither.
              if (!exercise.isTimed)
                IconButton(
                  icon: const Icon(LucideIcons.footprints),
                  tooltip: context.l10n.workoutWarmupCalculator,
                  onPressed: onWarmupCalculator,
                ),
              const SizedBox(width: 6),
              Expanded(
                child: AppButton(
                  label: context.l10n.workoutLogSet(working + 1),
                  icon: LucideIcons.plus,
                  // Deliberately not the accent. On this screen the accent
                  // belongs to the rest countdown, which is the thing you read
                  // from across a gym; a second accent surface here would make
                  // you check which of the two was shouting.
                  kind: AppButtonKind.secondary,
                  onPressed: () => onLog(SetType.normal),
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

  final SessionExerciseEntry planned;
  final List<LoggedSet> loggedSets;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = planned.targets;
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

/// What the card's options menu can do to an exercise.
enum _EntryAction { swap, superset, remove }

/// "Superset with …" under the card's title: what you go to straight after
/// this set, with no rest in between.
class _SupersetLine extends StatelessWidget {
  const _SupersetLine({required this.partners, required this.accent});

  final List<SessionExerciseEntry> partners;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.link, size: 15, color: accent),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              l10n.workoutSupersetWith(
                partners
                    .map((p) => p.exercise.name)
                    .reduce((a, b) => l10n.commonListAnd(a, b)),
              ),
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

/// Up-next rows that belong to one superset, held together by a rule down
/// their left edge and a label.
///
/// A rule rather than a box around them: the rows are already panes, and a
/// pane around panes is a heavier frame than "these go together" needs.
class _SupersetGroup extends ConsumerWidget {
  const _SupersetGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6, top: 2),
          child: Row(
            children: [
              Icon(LucideIcons.link, size: 14, color: accent),
              const SizedBox(width: 5),
              Text(
                context.l10n.workoutSupersetCaps,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accent.withValues(alpha: 0.55), width: 2),
            ),
          ),
          child: Column(children: children),
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

  final SessionExerciseEntry planned;
  final List<LoggedSet> loggedSets;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expected = planned.targets.warmupSets;
    final done = loggedSets.where((s) => s.isWarmup).length;
    final label = done < expected
        ? context.l10n.workoutWarmupProgress(done + 1, expected)
        : context.l10n.workoutWarmup;
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
        // Capped at about a third of the screen, so a long label ("Aufwärmen
        // 2/3", or any label at a large text size) shrinks to fit instead of
        // squeezing Log set — the one button the card is for — to nothing.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.32,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
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

  final SessionExerciseEntry planned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final suggestion = ref
        .watch(
          overloadSuggestionProvider((
            entry: planned.targets,
            exercise: planned.exercise,
          )),
        )
        .value;

    if (suggestion == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final weight = formatWeightUnit(suggestion.weight, unit, l10n: l10n);
    final (icon, text) = switch (suggestion.reason) {
      OverloadReason.earned => (
        LucideIcons.trendingUp,
        l10n.workoutSuggestionEarned(weight),
      ),
      OverloadReason.deload => (
        LucideIcons.trendingDown,
        l10n.workoutSuggestionDeload(weight),
      ),
      OverloadReason.atLimit => (
        LucideIcons.pause,
        l10n.workoutSuggestionAtLimit(weight),
      ),
      // A planned % of 1RM, and a training block's deload week — see
      // overloadSuggestionProvider for when each applies.
      OverloadReason.percentOfMax => (
        LucideIcons.percent,
        l10n.workoutSuggestionPercent(
          formatPercent(suggestion.targetPercent ?? 0, l10n: l10n),
          weight,
        ),
      ),
      OverloadReason.blockDeload => (
        LucideIcons.trendingDown,
        l10n.workoutSuggestionBlockDeload(
          formatPercent(suggestion.deloadPercent ?? 0, l10n: l10n),
          weight,
        ),
      ),
      _ => (LucideIcons.minus, l10n.workoutSuggestionSame(weight)),
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
    final l10n = context.l10n;
    final unit = ref.watch(weightUnitProvider);

    // Warm-ups and drop sets are dimmed rather than hidden or restyled:
    // they're still your work, just not the part the strength numbers are
    // about. Muted text plus the badge makes the divide readable at arm's
    // length without a heavy separator cutting the card in two.
    final muted = theme.colorScheme.onSurfaceVariant;
    final dimmed = !isWorkingSet(set);
    final rating = _ratingLabel(set, l10n);

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
                color: dimmed ? muted : accent,
              ),
            ),
          ),
          Expanded(
            child: Text(
              formatLoggedSet(
                weightKg: set.weight,
                reps: set.reps,
                seconds: set.seconds,
                unit: unit,
                l10n: l10n,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: dimmed ? muted : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (rating != null) ...[
            Text(
              rating,
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
            const SizedBox(width: 6),
          ],
          if (_badgeFor(set.type, l10n) case final badge?) ...[
            _SetTypeBadge(letter: badge, colour: muted),
            const SizedBox(width: 4),
          ],
          // Re-tagging is the common repair: you ramp up, the bar feels
          // light, and what you called a warm-up was really your first
          // working set — or the last set went to failure and you only
          // decided so afterwards. Without this the only fix is deleting the
          // row and logging it again from memory.
          //
          // The shared option sheet rather than a popup menu, whose rows are
          // too tight to hit with a thumb mid-workout.
          IconButton(
            icon: const Icon(LucideIcons.slidersHorizontal),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: context.l10n.workoutChangeSetTypeTooltip,
            onPressed: () async {
              final type = await showOptionPicker<SetType>(
                context: context,
                title: context.l10n.workoutSetTypeTitle,
                options: [
                  // Only a held set stores seconds.
                  for (final type in SetType.optionsFor(
                    timed: set.seconds != null,
                  ))
                    (
                      value: type,
                      label: type.localizedLabel(context.l10n),
                      subtitle: null,
                    ),
                ],
                selected: set.type,
              );
              if (type == null || type == set.type) return;
              await ref
                  .read(sessionRepositoryProvider)
                  .setSetType(id: set.id, type: type);
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.x),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: context.l10n.workoutDeleteSetTooltip,
            onPressed: () =>
                ref.read(sessionRepositoryProvider).deleteSet(set.id),
          ),
        ],
      ),
    );
  }
}

/// The letter a row of [type] is badged with, or null for an ordinary
/// working set — the default needs no label, and a badge on every row would
/// stop the unusual ones standing out.
String? _badgeFor(SetType type, AppLocalizations l10n) => switch (type) {
  SetType.warmup => l10n.workoutBadgeWarmup,
  SetType.drop => l10n.workoutBadgeDrop,
  SetType.failure => l10n.workoutBadgeFailure,
  SetType.normal => null,
};

/// "RPE 8" or "RIR 2", whichever the set was rated in, or null when unrated.
///
/// RPE and RIR are the same abbreviations in German; only a half step changes,
/// to "8,5".
String? _ratingLabel(LoggedSet set, AppLocalizations l10n) {
  final rpe = set.rpe;
  if (rpe != null) return 'RPE ${formatWeight(rpe, l10n: l10n)}';
  if (set.rir != null) return 'RIR ${set.rir}';
  return null;
}

/// The small letter that marks a warm-up, drop or failure row.
class _SetTypeBadge extends StatelessWidget {
  const _SetTypeBadge({required this.letter, required this.colour});

  final String letter;
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
        letter,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colour),
      ),
    );
  }
}

/// A workout with nothing in it yet: a free workout just started, or a day
/// whose plan was empty. Either way the way forward is the same button.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isFree, required this.onAdd});

  /// True for a free workout, which is *meant* to start empty — so it is
  /// greeted, not apologised for.
  final bool isFree;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.dumbbell,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              isFree
                  ? l10n.workoutFreeWorkoutName
                  : l10n.workoutEmptyNothingTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isFree
                  ? l10n.workoutEmptyFreeMessage
                  : l10n.workoutEmptyNothingMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: context.l10n.workoutAddExercise,
              icon: LucideIcons.plus,
              expand: false,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}
