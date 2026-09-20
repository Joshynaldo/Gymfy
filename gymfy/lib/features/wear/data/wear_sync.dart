import 'dart:async';

import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/units.dart';
import '../../exercises/data/exercise_repository.dart';
import '../../workout/data/rest_timer_controller.dart';
import '../../workout/data/rest_timer_repository.dart';
import '../../workout/data/session_repository.dart';
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
}) {
  if (session == null) return idleWearWorkout;

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
  final resting = rest != null && rest.remainingSeconds > 0;
  final endsAt = resting
      ? _toWholeSecond(
          now
              .add(Duration(seconds: rest.remainingSeconds))
              .millisecondsSinceEpoch,
        )
      : 0;

  return (
    active: true,
    workout: session.name,
    // The rest timer is the only thing that knows which exercise you are
    // actually on — it is started from the set you just logged. An empty
    // string when nothing is resting is honest; guessing the exercise from
    // the last logged set would be wrong as soon as you skip ahead.
    exercise: resting ? rest.exerciseName : '',
    sets: switch (loggedSets) {
      0 => 'No sets yet',
      1 => '1 set logged',
      _ => '$loggedSets sets logged',
    },
    restEndsAtMs: endsAt,
    restTotalSeconds: resting ? rest.totalSeconds : 0,
    lastSet: lastSet,
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

    final next = wearWorkoutFrom(
      session: session,
      rest: rest,
      loggedSets: logged.length,
      now: clock.now(),
      lastSet: describeRepeatableSet(
        lastWorkingSet(logged),
        ref.watch(weightUnitProvider),
      ),
    );

    // The rest timer rebuilds once a second while it runs. Sending on every
    // one of those would be ninety Data Layer writes per rest, all carrying
    // the same deadline — so only a real change goes out.
    //
    // Records compare by value, which is the whole reason the payload is one.
    if (next != _last) {
      _last = next;
      ref.read(wearBridgeProvider).push(next);
    }

    return next;
  }
}

/// Rounds epoch milliseconds to the nearest whole second.
///
/// Rounded rather than truncated so a deadline does not shift backwards by
/// up to a second, which would make the watch's last tick land early.
int _toWholeSecond(int ms) => ((ms + 500) ~/ 1000) * 1000;

/// Acts on the commands the watch sends back.
///
/// Kept apart from [WearSync], which is one-way. This is the reverse
/// channel, and separating them keeps the rule visible: the phone owns the
/// state, the watch asks it to change.
///
/// Deliberately limited to the rest timer for now. The rest timer lives in
/// memory on the phone, so a command here can never write to the database,
/// duplicate a set, or need a queue — none of the problems that make
/// logging *from* the watch the hard half. This proves the channel first.
@Riverpod(keepAlive: true)
class WearCommands extends _$WearCommands {
  @override
  void build() {
    final bridge = ref.watch(wearBridgeProvider);
    bridge.listen(_handle);
    ref.onDispose(() => bridge.listen(null));
  }

  /// Ids of repeat commands already applied.
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

  void _handle(String command) {
    // `read`, not `watch`: this runs from a platform callback, outside the
    // build, and reacting to the timer here would rebuild on every tick.
    final timer = ref.read(restTimerProvider.notifier);

    // Commands that carry an id arrive as "name:id".
    final separator = command.indexOf(':');
    final name = separator == -1 ? command : command.substring(0, separator);
    final id = separator == -1 ? '' : command.substring(separator + 1);

    switch (name) {
      case WearBridge.commandAddThirty:
        timer.adjust(30);
      case WearBridge.commandSkipRest:
        timer.stop();
      case WearBridge.commandRepeatSet:
        if (id.isEmpty || !_appliedIds.add(id)) return;
        if (_appliedIds.length > _rememberedIds) {
          _appliedIds.remove(_appliedIds.first);
        }
        unawaited(_repeatLastSet());
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

    final sets = await ref.read(sessionSetsProvider(session.id).future);
    final last = lastWorkingSet(sets);
    if (last == null || last.seconds != null) return;

    // Numbered within the *working* sets of that exercise, matching how the
    // phone numbers them — "so working sets read 1, 2, 3 however long the
    // ramp-up was". Counting warm-ups too would give a set logged from the
    // wrist a different number than the identical one logged on the phone.
    final working = sets.where(
      (s) => s.exerciseId == last.exerciseId && !s.isWarmup,
    );
    await ref
        .read(sessionRepositoryProvider)
        .logSet(
          sessionId: session.id,
          exerciseId: last.exerciseId,
          setNumber: working.length + 1,
          weight: last.weight,
          reps: last.reps,
        );

    // And start the rest, because logging a set is exactly when rest starts.
    //
    // Writing the set without this was the whole feature half-done: the set
    // appeared on both screens and then nothing happened, so the one thing
    // you actually wanted from the wrist — not having to touch the phone
    // between sets — still needed the phone. A set logged from the watch has
    // to behave like a set logged anywhere else.
    final exercise = await ref.read(exerciseProvider(last.exerciseId).future);
    await ref
        .read(restTimerProvider.notifier)
        .start(
          exerciseId: last.exerciseId,
          exerciseName: exercise?.name ?? '',
          seconds: ref.read(restForExerciseProvider(last.exerciseId)),
        );
  }
}

/// The most recent working set in [sets], or null if there is none.
///
/// Warm-ups are skipped. "Do that again" after a warm-up means the working
/// set you are building up to, not the empty-bar one — and a warm-up logged
/// as a working set from the wrist would quietly poison progressive
/// overload, which reads the top set of each session.
LoggedSet? lastWorkingSet(List<LoggedSet> sets) {
  for (final set in sets.reversed) {
    if (!set.isWarmup) return set;
  }
  return null;
}

/// Renders [set] as the label on the watch's repeat button.
///
/// Empty when there is nothing to repeat, which is also how the watch
/// decides whether to offer the button at all — one field, one meaning,
/// no separate "can repeat" flag to fall out of step with it.
String describeRepeatableSet(LoggedSet? set, WeightUnit unit) {
  if (set == null) return '';
  // A timed hold has no reps to repeat and no weight worth showing; it is
  // also the one kind of set where "the same again" means holding still for
  // a while, which is not a thing a button can do for you.
  if (set.seconds != null) return '';
  if (set.weight <= 0) return '${set.reps} reps';
  return '${formatWeightUnit(set.weight, unit)} x ${set.reps}';
}
