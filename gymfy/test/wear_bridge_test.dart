// The phone half of the Wear OS companion.
//
// Two kinds of test here. The payload builder is a pure function and is
// tested as one. The rest guard things that fail *silently* across a
// language boundary: a path typo means the watch simply never hears
// anything, and no amount of Dart-side correctness would show it.

import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/wear/data/wear_bridge.dart';
import 'package:gymfy/features/wear/data/wear_sync.dart';
import 'package:gymfy/shared/database/app_database.dart';

WorkoutSession _session({String name = 'Push A'}) => WorkoutSession(
  id: 1,
  name: name,
  startedAt: DateTime(2026, 9, 20, 18),
  completedAt: null,
);

void main() {
  final now = DateTime(2026, 9, 20, 18, 30);

  group('the payload', () {
    test('is idle when no workout is running', () {
      final payload = wearWorkoutFrom(
        session: null,
        rest: null,
        loggedSets: 0,
        now: now,
      );

      expect(payload, idleWearWorkout);
      expect(
        payload.active,
        isFalse,
        reason: 'a finished session must blank the watch rather than leave '
            'yesterday sitting there looking current',
      );
    });

    test('carries the workout name and a set line', () {
      final payload = wearWorkoutFrom(
        session: _session(),
        rest: null,
        loggedSets: 12,
        now: now,
      );

      expect(payload.active, isTrue);
      expect(payload.workout, 'Push A');
      expect(payload.sets, '12 sets logged');
    });

    test('counts sets in words the watch can draw unmodified', () {
      // The watch must never do grammar. It has no idea what a set is.
      for (final (count, expected) in const [
        (0, 'No sets yet'),
        (1, '1 set logged'),
        (2, '2 sets logged'),
      ]) {
        final payload = wearWorkoutFrom(
          session: _session(),
          rest: null,
          loggedSets: count,
          now: now,
        );
        expect(payload.sets, expected);
      }
    });
  });

  group('the rest timer', () {
    test('is sent as a deadline, not as a countdown', () {
      // The whole reason: one message per rest instead of one per second,
      // and the watch stays right while the phone is out of range.
      final payload = wearWorkoutFrom(
        session: _session(),
        rest: (
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          totalSeconds: 120,
          remainingSeconds: 90,
        ),
        loggedSets: 3,
        now: now,
      );

      expect(
        payload.restEndsAtMs,
        now.add(const Duration(seconds: 90)).millisecondsSinceEpoch,
      );
      expect(payload.restTotalSeconds, 120);
      expect(payload.exercise, 'Bench Press');
    });

    test('holds still across ticks, so it is sent once and not ninety times', () {
      // Found on a real watch, not here: a 90-second rest pushed a new
      // deadline every single second. The timer reports whole seconds
      // remaining while `now` moves continuously, so `now + remaining`
      // landed a few milliseconds apart on each tick, every payload compared
      // unequal, and the throttle never fired once.
      //
      // Simulates the tick pattern that caused it: the clock advancing by
      // slightly-off-one-second steps while remaining counts down by one.
      final deadlines = <int>{};
      for (var tick = 0; tick < 10; tick++) {
        deadlines.add(
          wearWorkoutFrom(
            session: _session(),
            rest: (
              exerciseId: 'bench',
              exerciseName: 'Bench Press',
              totalSeconds: 90,
              remainingSeconds: 90 - tick,
            ),
            loggedSets: 1,
            // Deliberately not exact seconds — real ticks drift.
            now: now.add(Duration(milliseconds: tick * 1000 + tick * 3)),
          ).restEndsAtMs,
        );
      }

      expect(
        deadlines,
        hasLength(1),
        reason: 'ten ticks of the same rest must produce one deadline, or '
            'the send-once-per-rest throttle does nothing',
      );
    });

    test('a finished rest sends no deadline at all', () {
      // remainingSeconds hits zero and stays there so the phone can say
      // "rest over". Forwarding that as a deadline would leave the watch
      // drawing a ring at 0:00 forever.
      final payload = wearWorkoutFrom(
        session: _session(),
        rest: (
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          totalSeconds: 120,
          remainingSeconds: 0,
        ),
        loggedSets: 3,
        now: now,
      );

      expect(payload.restEndsAtMs, 0);
      expect(payload.restTotalSeconds, 0);
      expect(payload.exercise, isEmpty);
    });

    test('moves with the clock, so it is testable without waiting', () {
      final rest = (
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
        totalSeconds: 60,
        remainingSeconds: 60,
      );

      final early = withClock(
        Clock.fixed(now),
        () => wearWorkoutFrom(
          session: _session(),
          rest: rest,
          loggedSets: 1,
          now: clock.now(),
        ),
      );
      final later = withClock(
        Clock.fixed(now.add(const Duration(seconds: 30))),
        () => wearWorkoutFrom(
          session: _session(),
          rest: rest,
          loggedSets: 1,
          now: clock.now(),
        ),
      );

      expect(later.restEndsAtMs - early.restEndsAtMs, 30 * 1000);
    });
  });

  group('payloads compare by value', () {
    // WearSync only pushes when the payload changes. That relies entirely on
    // record equality — if this stopped holding, every rest-timer tick would
    // become a Data Layer write, ninety per rest, on two batteries.
    test('identical state produces an equal payload', () {
      WearWorkout build() => wearWorkoutFrom(
        session: _session(),
        rest: null,
        loggedSets: 4,
        now: now,
      );

      expect(build(), build());
    });

    test('and a changed set count does not', () {
      final a = wearWorkoutFrom(
        session: _session(),
        rest: null,
        loggedSets: 4,
        now: now,
      );
      final b = wearWorkoutFrom(
        session: _session(),
        rest: null,
        loggedSets: 5,
        now: now,
      );

      expect(a, isNot(b));
    });
  });

  group('the two sides agree', () {
    // A path typo is the worst failure mode this feature has: nothing
    // crashes, no test fails, the watch just stays blank forever. Both
    // constants are read from source here because there is no shared
    // language to put them in.
    String read(String path) => File(path).readAsStringSync();

    test('on the Data Layer path', () {
      final kotlinPhone = read(
        'android/app/src/main/kotlin/de/kopten/gymfy/WearBridge.kt',
      );
      final kotlinWatch = read(
        'android/wear/src/main/kotlin/de/kopten/gymfy/wear/WorkoutState.kt',
      );

      final path = RegExp(r'WORKOUT_PATH\s*=\s*"([^"]+)"');
      final onPhone = path.firstMatch(kotlinPhone)?.group(1);
      final onWatch = path.firstMatch(kotlinWatch)?.group(1);

      expect(onPhone, isNotNull, reason: 'phone WORKOUT_PATH not found');
      expect(onWatch, isNotNull, reason: 'watch WORKOUT_PATH not found');
      expect(onWatch, onPhone);
    });

    test('on the command path and the command names', () {
      // The reverse channel has the same silent-failure shape as the
      // forward one, with a worse symptom: a mismatched command name means
      // the button on your wrist does nothing at all, and nothing anywhere
      // says why.
      final kotlinPhone = read(
        'android/app/src/main/kotlin/de/kopten/gymfy/WearBridge.kt',
      );
      final kotlinWatch = read(
        'android/wear/src/main/kotlin/de/kopten/gymfy/wear/WorkoutState.kt',
      );

      final path = RegExp(r'COMMAND_PATH\s*=\s*"([^"]+)"');
      expect(
        path.firstMatch(kotlinWatch)?.group(1),
        path.firstMatch(kotlinPhone)?.group(1),
        reason: 'the watch would send commands into the void',
      );

      // Dart declares the names; the watch has to spell them identically.
      for (final command in const [
        WearBridge.commandAddThirty,
        WearBridge.commandSkipRest,
      ]) {
        expect(
          kotlinWatch,
          contains('"$command"'),
          reason: 'the watch never sends "$command", so the phone handling '
              'it has no effect',
        );
      }
    });

    test('on the method channel name', () {
      final kotlin = read(
        'android/app/src/main/kotlin/de/kopten/gymfy/WearBridge.kt',
      );
      final channel = RegExp(r'CHANNEL\s*=\s*"([^"]+)"').firstMatch(kotlin);

      expect(channel, isNotNull);
      expect(WearBridge.channel.name, channel!.group(1));
    });

    test('on every field name in the payload', () {
      // Kotlin reads each field by string key. A rename on the Dart side
      // leaves the watch silently showing a default.
      final watch = read(
        'android/wear/src/main/kotlin/de/kopten/gymfy/wear/WorkoutState.kt',
      );
      for (final field in const [
        'active',
        'workout',
        'exercise',
        'sets',
        'restEndsAtMs',
        'restTotalSeconds',
        'lastSet',
        'updatedAtMs',
      ]) {
        expect(
          watch,
          contains('"$field"'),
          reason: 'the watch never reads "$field", so the phone sending it '
              'has no effect',
        );
      }
    });
  });
}
