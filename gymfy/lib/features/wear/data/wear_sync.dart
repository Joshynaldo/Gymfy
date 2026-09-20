import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../workout/data/rest_timer_controller.dart';
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
          now.add(Duration(seconds: rest.remainingSeconds)).millisecondsSinceEpoch,
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
    final sets = session == null
        ? 0
        : (ref.watch(sessionSetsProvider(session.id)).value?.length ?? 0);

    final next = wearWorkoutFrom(
      session: session,
      rest: rest,
      loggedSets: sets,
      now: clock.now(),
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
