import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../l10n/app_language.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/data/settings_repository.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/units.dart';
import '../../exercises/data/exercise_repository.dart';
import '../../workout/data/next_set.dart';
import '../../workout/data/rest_timer_controller.dart';
import '../../workout/data/rest_timer_repository.dart';
import '../../workout/data/session_repository.dart';
import '../../workout/data/supersets.dart';
import 'wear_bridge.dart';

part 'wear_sync.g.dart';

/// Builds the watch payload from the live workout and the rest timer.
///
/// Pure, and separated from the sending so it can be tested without a
/// platform channel: the interesting part is *what the watch is told*, and
/// that is a function of two pieces of state.
WearWorkout wearWorkoutFrom({
  required WorkoutSession? session,
  required RestTimerState? rest,
  required int loggedSets,
  required DateTime now,
  String lastSet = '',
  NextSet? next,
  WeightUnit unit = WeightUnit.kg,
  AppLocalizations? l10n,
}) {
  if (session == null) return idleWearWorkout;
  final strings = l10n ?? englishLocalizations;

  // A deadline rather than a countdown — see WearWorkout.restEndsAtMs. Built
  // from `now` rather than read from the timer so the arithmetic is testable
  // with a fake clock, the same way the rest timer itself is.
  //
  // **Rounded to a whole second, and that rounding is load-bearing.** The
  // timer ticks once a second and reports whole seconds remaining, but `now`
  // moves continuously, so `now + remaining` lands a few milliseconds apart
  // on every tick. Those milliseconds made each payload unequal, which
  // defeated the send-once-per-rest throttle completely: measured on a real
  // watch, a 90-second rest pushed a new deadline every single second —
  // exactly the ninety messages the deadline design exists to avoid.
  //
  // Nothing is lost. The watch counts in seconds and cannot draw finer.
  final endsAt = restDeadlineMs(rest, now);
  final resting = endsAt > 0;

  return (
    active: true,
    workout: session.name,
    // The rest timer is the only thing that knows which exercise you are
    // actually on — it is started from the set you just logged. An empty
    // string when nothing is resting is honest; guessing the exercise from
    // the last logged set would be wrong as soon as you skip ahead.
    exercise: resting ? rest!.exerciseName : '',
    // Worded on the phone, in the phone app's language: the watch draws
    // these lines as they arrive and has no words of its own for them.
    sets: strings.wearSetsLogged(loggedSets),
    restEndsAtMs: endsAt,
    restTotalSeconds: resting ? rest!.totalSeconds : 0,
    lastSet: lastSet,
    nextExercise: next?.exerciseName ?? '',
    nextExerciseId: next?.exerciseId ?? '',
    nextSet: next == null ? '' : describeSetPosition(next, l10n: l10n),
    // In the display unit and on a loadable step, so an untouched value sent
    // back converts to exactly what the phone would have logged itself.
    nextWeight: next == null
        ? 0.0
        : weightIn(roundToLoadable(next.weightKg, unit), unit),
    nextReps: next == null ? 0 : (next.seconds ?? next.reps),
    nextTimed: next?.seconds != null,
    weightUnit: next == null ? '' : unit.name,
    weightStep: next == null ? 0.0 : wearWeightStep(unit),
  );
}

/// One press of + or - on the watch: a pair of 1.25 kg plates, or of 2.5 lb
/// ones — the smallest jump most gyms can load on a bar, and coarse enough
/// that a 60 kg change is not forty presses.
double wearWeightStep(WeightUnit unit) => switch (unit) {
  WeightUnit.kg => 2.5,
  WeightUnit.lbs => 5,
};

/// When the running rest ends, as whole-second epoch milliseconds, or zero
/// when nothing is resting (including a rest that has just run out).
///
/// Shared by the watch payload and the ongoing notification, which both hand
/// the deadline to something that counts down on its own — and both rely on
/// the rounding to keep the value still across ticks.
int restDeadlineMs(RestTimerState? rest, DateTime now) {
  if (rest == null || rest.remainingSeconds <= 0) return 0;
  return _toWholeSecond(
    now.add(Duration(seconds: rest.remainingSeconds)).millisecondsSinceEpoch,
  );
}

/// Keeps the watch in step with the phone.
///
/// Watched, not polled: the providers below already push, and a timer here
/// would send the same payload over and over for the length of a workout —
/// on two batteries.
///
/// Nothing reads this provider's value; it exists for the side effect, so it
/// has to be kept alive explicitly or it would be disposed the moment the
/// screen that created it went away, which is exactly when the phone goes in
/// a pocket and the watch matters most.
@Riverpod(keepAlive: true)
class WearSync extends _$WearSync {
  WearWorkout? _last;

  @override
  WearWorkout build() {
    final session = ref.watch(inProgressSessionProvider).value;
    final rest = ref.watch(restTimerProvider);
    final logged = session == null
        ? const <LoggedSet>[]
        : (ref.watch(sessionSetsProvider(session.id)).value ?? const []);
    final next = session == null
        ? null
        : ref.watch(nextSetProvider(session.id)).value;
    final unit = ref.watch(weightUnitProvider);
    // Watched, so switching the app's language re-words the watch at once.
    final l10n = ref.watch(appLocalizationsProvider);

    final payload = wearWorkoutFrom(
      session: session,
      rest: rest,
      loggedSets: logged.length,
      now: clock.now(),
      lastSet: describeRepeatableSet(lastWorkingSet(logged), unit, l10n: l10n),
      next: next,
      unit: unit,
      l10n: l10n,
    );

    // The rest timer rebuilds once a second while it runs. Sending on every
    // one of those would be ninety Data Layer writes per rest, all carrying
    // the same deadline — so only a real change goes out.
    //
    // Records compare by value, which is the whole reason the payload is one.
    if (payload != _last) {
      _last = payload;
      ref.read(wearBridgeProvider).push(payload);
    }

    return payload;
  }
}

/// Rounds epoch milliseconds to the nearest whole second.
///
/// Rounded rather than truncated so a deadline does not shift backwards by
/// up to a second, which would make the watch's last tick land early.
int _toWholeSecond(int ms) => ((ms + 500) ~/ 1000) * 1000;

/// The heaviest weight, longest hold and most reps a remote log may carry.
///
/// The same ceilings the log sheet's keypad has — six characters of weight,
/// two digits of reps, 99:59 of hold — so a set from the wrist or the shade
/// can never be one the phone itself would have refused to type.
const maxRemoteWeight = 9999.0;
const maxRemoteReps = 99;
const maxRemoteSeconds = 99 * 60 + 59;

/// What a valid remote log writes: kilograms, and reps or seconds.
typedef RemoteSet = ({double weightKg, int reps, int? seconds});

/// Checks [request] against the exercise it names, and converts it to what is
/// stored. Null when it does not fit.
///
/// The watch's numbers are whatever its controls allowed, and its idea of the
/// exercise is as old as its last payload, so nothing is taken on trust: a
/// rep count for a plank, a hold for a bench press, a negative weight or one
/// past the keypad's ceiling are all refused rather than clamped. A clamped
/// set is still a set nobody did.
RemoteSet? validateRemoteSet(RemoteSetRequest request, Exercise exercise) {
  final weight = request.weight;
  if (!weight.isFinite || weight < 0 || weight > maxRemoteWeight) return null;
  final kg = weightToKilograms(weight, request.unit);

  if (exercise.isTimed) {
    final seconds = request.seconds;
    if (seconds == null || seconds < 1 || seconds > maxRemoteSeconds) {
      return null;
    }
    // One or the other, never both — the rule every held set follows.
    return (weightKg: kg, reps: 0, seconds: seconds);
  }

  final reps = request.reps;
  if (reps == null || reps < 1 || reps > maxRemoteReps) return null;
  return (weightKg: kg, reps: reps, seconds: null);
}

/// Acts on the commands the watch sends back — and the buttons on the
/// ongoing workout notification, which arrive through the same door.
///
/// Kept apart from [WearSync], which is one-way. This is the reverse
/// channel, and separating them keeps the rule visible: the phone owns the
/// state, the watch asks it to change.
@Riverpod(keepAlive: true)
class WearCommands extends _$WearCommands {
  @override
  void build() {
    final bridge = ref.watch(wearBridgeProvider);
    bridge.listen(_handle);
    ref.onDispose(() => bridge.listen(null));
  }

  /// Ids of set commands already applied — repeats and logs share them.
  ///
  /// The whole defence against a double tap. A watch button is small, it is
  /// pressed with a sweaty finger mid-workout, and the confirmation is a
  /// round trip away — so two taps for one intended set is the *normal*
  /// case, not the edge case. Without this the second one is a set in your
  /// history you did not perform, which is worse than a missed one: you
  /// cannot tell later that it was wrong.
  ///
  /// Bounded, because it must not grow for the length of a session. Only
  /// the recent ones can plausibly be duplicates.
  final _appliedIds = <String>{};
  static const _rememberedIds = 32;

  /// Records [id] as applied, or says it already was.
  bool _firstTime(String id) {
    if (id.isEmpty || !_appliedIds.add(id)) return false;
    if (_appliedIds.length > _rememberedIds) {
      _appliedIds.remove(_appliedIds.first);
    }
    return true;
  }

  /// The set writes still in flight, chained.
  ///
  /// A set is numbered from the sets already there, so two writes that
  /// overlapped — the wrist and the shade at once — would both read "two so
  /// far" and both write set 3. One after the other, they cannot.
  Future<void> _writes = Future<void>.value();

  Future<void> _oneAtATime(Future<void> Function() write) {
    final done = _writes.then((_) => write());
    // A write that failed must not wedge every one after it.
    _writes = done.catchError((Object _) {});
    return done;
  }

  /// Applies one command. The future completes once it has fully landed —
  /// set written, rest started — because the notification's broadcast is
  /// held open until then (see [WearBridge.listen]).
  Future<void> _handle(String command) async {
    // `read`, not `watch`: this runs from a platform callback, outside the
    // build, and reacting to the timer here would rebuild on every tick.
    final timer = ref.read(restTimerProvider.notifier);

    // Commands that carry an argument arrive as "name:argument".
    final separator = command.indexOf(':');
    final name = separator == -1 ? command : command.substring(0, separator);
    final argument = separator == -1 ? '' : command.substring(separator + 1);

    switch (name) {
      case WearBridge.commandAddThirty:
        timer.adjust(30);
      case WearBridge.commandSkipRest:
        timer.stop();
      case WearBridge.commandRepeatSet:
        if (!_firstTime(argument)) return;
        await _oneAtATime(_repeatLastSet);
      case WearBridge.commandLogSet:
        final request = WearBridge.parseLogSet(argument);
        if (request == null || !_firstTime(request.id)) return;
        await _oneAtATime(() => _logRequested(request));
      // An unknown command means the watch is on a newer build than the
      // phone. Ignoring it is right: the alternative is guessing.
      default:
        break;
    }
  }

  /// Logs another set identical to the last working one.
  ///
  /// Reads the state fresh rather than trusting anything the watch sent:
  /// the watch's idea of the last set is however old its last payload is,
  /// and the phone is the only thing that knows what is actually in the
  /// database. The watch asks for "another one of those" and the phone
  /// decides what that means.
  Future<void> _repeatLastSet() async {
    final session = ref.read(inProgressSessionProvider).value;
    if (session == null) return;

    // From the repository, not the sets provider: a provider that already
    // has a value hands that back at once, and a set logged a moment ago may
    // not have reached it yet — "repeat" would then find nothing to repeat.
    final sets = await ref
        .read(sessionRepositoryProvider)
        .watchSessionSets(session.id)
        .first;
    final last = lastWorkingSet(sets);
    if (last == null || last.seconds != null) return;

    await _logAndRest(
      session: session,
      exerciseId: last.exerciseId,
      weightKg: last.weight,
      reps: last.reps,
      // The same kind of set again: another set to failure is one too.
      setType: last.type,
    );
  }

  /// Logs the set the watch or the notification asked for, if it still fits
  /// the workout.
  ///
  /// The exercise has to be in the running order: one the watch still shows
  /// but that has since been removed or swapped away is refused, rather than
  /// quietly reappearing with a set against it.
  Future<void> _logRequested(RemoteSetRequest request) async {
    final session = ref.read(inProgressSessionProvider).value;
    if (session == null) return;

    final order = await ref
        .read(sessionRepositoryProvider)
        .watchSessionExercises(session.id)
        .first;
    final entry = order
        .where((e) => e.exercise.id == request.exerciseId)
        .firstOrNull;
    if (entry == null) return;

    final set = validateRemoteSet(request, entry.exercise);
    if (set == null) return;

    await _logAndRest(
      session: session,
      exerciseId: entry.exercise.id,
      weightKg: set.weightKg,
      reps: set.reps,
      seconds: set.seconds,
      setType: SetType.normal,
    );
  }

  /// Writes a working set through the same repository call the log sheet
  /// uses, then does what logging a set on the phone does next.
  Future<void> _logAndRest({
    required WorkoutSession session,
    required String exerciseId,
    required double weightKg,
    required int reps,
    int? seconds,
    required SetType setType,
  }) async {
    final repository = ref.read(sessionRepositoryProvider);

    // Fresh from the database rather than a provider's last value: two taps
    // in a row (two *different* ids) must number 3 and 4, not 3 and 3.
    final before = await repository.watchSessionSets(session.id).first;

    // Numbered within the *working* sets of that exercise, matching how the
    // phone numbers them — "so working sets read 1, 2, 3 however long the
    // ramp-up was". Counting warm-ups too would give a set logged from the
    // wrist a different number than the identical one logged on the phone.
    await repository.logSet(
      sessionId: session.id,
      exerciseId: exerciseId,
      setNumber: workingPhaseSets(before, exerciseId) + 1,
      weight: weightKg,
      reps: reps,
      seconds: seconds,
      setType: setType,
    );

    // And start the rest, because logging a set is exactly when rest starts.
    //
    // Writing the set without this was the whole feature half-done: the set
    // appeared on both screens and then nothing happened, so the one thing
    // you actually wanted from the wrist — not having to touch the phone
    // between sets — still needed the phone. A set logged from the watch has
    // to behave like a set logged anywhere else.
    //
    // Including supersets: mid-superset a set logged on the phone starts no
    // rest and moves the card to the next exercise of the group, so a set
    // from the wrist or the shade does both too — and the next set the
    // notification and the watch offer is then the partner's. Read from the
    // repository rather than a provider, which nothing may be listening to
    // while the phone is in a pocket.
    final order = await repository.watchSessionExercises(session.id).first;
    final entry = order.where((e) => e.exercise.id == exerciseId).firstOrNull;
    if (entry != null && !setType.isWarmupPhase) {
      final workingDone = <String, int>{exerciseId: 1};
      for (final set in before) {
        if (set.isWarmup) continue;
        workingDone[set.exerciseId] = (workingDone[set.exerciseId] ?? 0) + 1;
      }
      final step = supersetStepAfter(
        order,
        entry,
        (e) => e.supersetGroup,
        hasSetsLeft: (e) =>
            (workingDone[e.exercise.id] ?? 0) < e.targets.defaultSets,
      );
      if (step != null) {
        ref
            .read(pickedExerciseProvider(session.id).notifier)
            .pick(step.next?.exercise.id);
        if (!step.rests) return;
      }
    }

    // The name from the running order when the exercise is in it, and from
    // the repository otherwise — never a bare read of `exerciseProvider`,
    // which nothing listens to with the phone in a pocket, so its stream
    // stays paused and the read never completes (the rest never started).
    final name =
        entry?.exercise.name ??
        (await ref
                .read(exerciseRepositoryProvider)
                .watchExercise(exerciseId)
                .first)
            ?.name;
    final restSeconds = await _restSecondsFor(exerciseId);
    await ref
        .read(restTimerProvider.notifier)
        .start(
          exerciseId: exerciseId,
          exerciseName: name ?? '',
          seconds: restSeconds,
        );
  }

  /// The rest length for [exerciseId], read from the repositories.
  ///
  /// Not `restForExerciseProvider`: it is built from two streams, and with
  /// the phone in a pocket nothing is listening to either, so a read of it
  /// answers with the 90-second fallback before either row has loaded — a
  /// custom rest quietly ignored for every set logged from the wrist.
  Future<int> _restSecondsFor(String exerciseId) async {
    final own = await ref
        .read(restTimerRepositoryProvider)
        .watchForExercise(exerciseId)
        .first;
    if (own != null) return own;
    final raw = await ref
        .read(settingsRepositoryProvider)
        .readRaw(defaultRestSecondsSetting);
    return parseRestSeconds(raw) ?? defaultRestSeconds;
  }
}

/// The most recent working set in [sets], or null if there is none.
///
/// Warm-ups and drop sets are skipped ([isWorkingSet]). "Do that again" after
/// a warm-up means the working set you are building up to, not the empty-bar
/// one — and a warm-up or a stripped-down drop set logged as a working set
/// from the wrist would quietly poison progressive overload, which reads the
/// top set of each session.
LoggedSet? lastWorkingSet(List<LoggedSet> sets) {
  for (final set in sets.reversed) {
    if (isWorkingSet(set)) return set;
  }
  return null;
}

/// Renders [set] as the label on the watch's repeat button, in [l10n]'s
/// language (English without it).
///
/// Empty when there is nothing to repeat, which is also how the watch
/// decides whether to offer the button at all — one field, one meaning,
/// no separate "can repeat" flag to fall out of step with it.
String describeRepeatableSet(
  LoggedSet? set,
  WeightUnit unit, {
  AppLocalizations? l10n,
}) {
  if (set == null) return '';
  // A timed hold has no reps to repeat and no weight worth showing; it is
  // also the one kind of set where "the same again" means holding still for
  // a while, which is not a thing a button can do for you.
  if (set.seconds != null) return '';
  final strings = l10n ?? englishLocalizations;
  if (set.weight <= 0) return strings.wearRepeatReps(set.reps);
  return strings.wearRepeatSet(
    formatWeightUnit(set.weight, unit, l10n: l10n),
    set.reps,
  );
}
