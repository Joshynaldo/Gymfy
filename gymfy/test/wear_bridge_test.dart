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
import 'package:gymfy/features/workout_notification/data/workout_notification.dart';
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
        WearBridge.commandRepeatSet,
        WearBridge.commandLogSet,
      ]) {
        expect(
          kotlinWatch,
          contains('"$command"'),
          reason: 'the watch never sends "$command", so the phone handling '
              'it has no effect',
        );
      }
    });

    test('on every field of a log command', () {
      // The watch writes the JSON, Dart reads it. A key spelled differently
      // makes every log from the wrist malformed — refused, silently.
      final watch = read(
        'android/wear/src/main/kotlin/de/kopten/gymfy/wear/WorkoutState.kt',
      );
      for (final field in const [
        WearBridge.logFieldId,
        WearBridge.logFieldExercise,
        WearBridge.logFieldWeight,
        WearBridge.logFieldUnit,
      ]) {
        expect(
          watch,
          contains('.put("$field"'),
          reason: 'the watch never writes "$field" into a log command',
        );
      }
      // Reps and seconds are chosen between, never both written — the
      // phone refuses a command carrying both.
      expect(
        watch,
        contains(
          '.put(if (state.nextTimed) "${WearBridge.logFieldSeconds}" '
          'else "${WearBridge.logFieldReps}"',
        ),
        reason: 'the watch never writes reps or seconds into a log command',
      );
    });

    test('on how a weight is written', () {
      // The watch steps the weight with + and -, so it formats the number
      // itself. With a dot always, a German phone's "82,5 kg" read
      // "82.5 kg" on the wrist; and printed raw, a converted pound value
      // read "149.99999999999997".
      final state = read(
        'android/wear/src/main/kotlin/de/kopten/gymfy/wear/WorkoutState.kt',
      );
      final activity = read(
        'android/wear/src/main/kotlin/de/kopten/gymfy/wear/MainActivity.kt',
      );

      expect(
        state,
        contains('fun formatWeight(value: Double, separator: String'),
      );
      expect(state, contains('.replace(".", separator)'));
      expect(state, contains('.setScale(2, RoundingMode.HALF_UP)'));
      expect(
        activity,
        contains('formatWeight(weight, state.decimalSeparator)'),
        reason: 'the stepper must use the separator the phone sent',
      );
      expect(
        RegExp(r'formatWeight\(weight\)').hasMatch(activity),
        isFalse,
        reason: 'a weight written with the default dot',
      );
    });

    test('on the method a command is delivered to', () {
      // The watch's commands and the notification's buttons both arrive
      // through this one method.
      final kotlin = read(
        'android/app/src/main/kotlin/de/kopten/gymfy/WearBridge.kt',
      );
      final method = RegExp(
        r'COMMAND_METHOD\s*=\s*"([^"]+)"',
      ).firstMatch(kotlin)?.group(1);

      expect(method, WearBridge.commandMethod);
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
      final sent = _mapKeys(
        read('lib/features/wear/data/wear_bridge.dart'),
        after: "'pushWorkout', {",
      );
      final readByWatch = {
        for (final match in RegExp(
          r'map\.(?:getString|getBoolean|getDouble|getLong|getInt|number)'
          r'\("(\w+)"',
        ).allMatches(watch))
          match.group(1)!,
      };

      // Read from the Dart source rather than listed here, so a field added
      // to the payload is checked without anyone remembering to add it.
      expect(
        sent,
        containsAll(const [
          'active',
          'workout',
          'exercise',
          'sets',
          'restEndsAtMs',
          'restTotalSeconds',
          'lastSet',
          'updatedAtMs',
          'nextExercise',
          'nextExerciseId',
          'nextSet',
          'nextWeight',
          'nextReps',
          'nextTimed',
          'weightUnit',
          'weightStep',
          'decimalSeparator',
        ]),
        reason: 'the push map could not be read out of wear_bridge.dart',
      );
      for (final field in sent) {
        expect(
          readByWatch,
          contains(field),
          reason: 'the watch never reads "$field", so the phone sending it '
              'has no effect',
        );
      }
      // And the other way: a key the watch reads that the phone never sends
      // is a typo on the Kotlin side, and reads as a default forever.
      for (final field in readByWatch) {
        expect(
          sent,
          contains(field),
          reason: 'the watch reads "$field", which the phone never sends',
        );
      }
    });
  });

  group('the workout notification', () {
    String read(String path) => File(path).readAsStringSync();
    final kotlin = read(
      'android/app/src/main/kotlin/de/kopten/gymfy/WorkoutNotification.kt',
    );

    test('is shown and cleared by the same method names', () {
      String? constant(String name) =>
          RegExp('$name\\s*=\\s*"([^"]+)"').firstMatch(kotlin)?.group(1);

      expect(constant('SHOW_METHOD'), WorkoutNotificationBridge.showMethod);
      expect(constant('CLEAR_METHOD'), WorkoutNotificationBridge.clearMethod);
      // Routed to by the bridge, which owns the channel.
      final bridge = read(
        'android/app/src/main/kotlin/de/kopten/gymfy/WearBridge.kt',
      );
      expect(bridge, contains('WorkoutNotification.SHOW_METHOD ->'));
      expect(bridge, contains('WorkoutNotification.CLEAR_METHOD ->'));
    });

    test('reads every field Dart sends, and nothing else', () {
      final sent = _mapKeys(
        read(
          'lib/features/workout_notification/data/workout_notification.dart',
        ),
        after: 'showMethod, {',
      );
      final readByKotlin = {
        for (final match in RegExp(r'fields\["(\w+)"\]').allMatches(kotlin))
          match.group(1)!,
      };

      expect(
        sent,
        containsAll(const [
          'title',
          'text',
          'bigText',
          'subText',
          'restEndsAtMs',
          'logCommand',
        ]),
      );
      expect(readByKotlin, sent);
    });

    test('sends the rest commands Dart handles', () {
      // A misspelt command here is a button that does nothing.
      expect(
        kotlin,
        contains('COMMAND_ADD_THIRTY = "${WearBridge.commandAddThirty}"'),
      );
      expect(
        kotlin,
        contains('COMMAND_SKIP_REST = "${WearBridge.commandSkipRest}"'),
      );
    });

    test(
      'hides the workout on a lock screen set to hide sensitive content',
      () {
        // PUBLIC with no public version would show the workout, the exercise
        // and "Next: 80 kg × 8 reps" — and working buttons — to anyone holding
        // the locked phone, whatever the user chose in Android's settings.
        expect(kotlin, isNot(contains('VISIBILITY_PUBLIC')));
        expect(
          kotlin,
          contains('.setVisibility(Notification.VISIBILITY_PRIVATE)'),
        );
        expect(kotlin, contains('.setPublicVersion(publicVersion('));

        // The public version: a generic title and the countdown, nothing
        // else. Read out of its own function so a field or button added to it
        // later shows up here.
        final start = kotlin.indexOf('private fun publicVersion(');
        expect(start, isNot(-1));
        final end = kotlin.indexOf('return builder.build()', start);
        final body = kotlin.substring(start, end);
        for (final leak in const [
          '"title"',
          '"text"',
          '"bigText"',
          '"subText"',
          '"logCommand"',
          'addAction',
          'setContentText',
          'setStyle',
        ]) {
          expect(body, isNot(contains(leak)), reason: leak);
        }
        expect(body, contains('setContentTitle(channelName(fields))'));
      },
    );

    test('has a receiver for its buttons', () {
      // Without the manifest entry the broadcast goes nowhere and the
      // buttons silently do nothing.
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      expect(manifest, contains('android:name=".WorkoutActionReceiver"'));
      expect(
        read(
          'android/app/src/main/kotlin/de/kopten/gymfy/WorkoutActionReceiver.kt',
        ),
        contains('class WorkoutActionReceiver : BroadcastReceiver()'),
      );
    });
  });

  test('neither app can reach the internet', () {
    // Offline-only is a promise, not an accident: everything here is
    // on-device IPC (the Data Layer, a local broadcast). The debug and
    // profile manifests keep Flutter's own INTERNET entry for the tooling;
    // the shipped ones must never gain it.
    for (final path in const [
      'android/app/src/main/AndroidManifest.xml',
      'android/wear/src/main/AndroidManifest.xml',
    ]) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains('android.permission.INTERNET')),
        reason: path,
      );
    }
  });
}

/// The string keys of the map literal that follows [after] in [source].
///
/// Good enough for the two hand-written maps it reads — flat, one
/// `'key': value` per line, no braces inside — and it fails loudly (an empty
/// set) if either ever stops looking like that.
Set<String> _mapKeys(String source, {required String after}) {
  final start = source.indexOf(after);
  if (start == -1) return const {};
  final end = source.indexOf('}', start + after.length);
  final body = source.substring(start + after.length, end);
  return {
    for (final match in RegExp(
      r"^\s*'(\w+)':",
      multiLine: true,
    ).allMatches(body))
      match.group(1)!,
  };
}
