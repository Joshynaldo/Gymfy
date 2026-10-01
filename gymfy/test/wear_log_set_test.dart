// Logging a set with your own numbers, from the watch or the notification.
//
// Stage 2 of the companion: the wrist no longer only repeats the last set,
// it sends weight and reps. That makes it the second thing in the app that
// can write a set the user never sees being written — so the phone checks
// everything, writes through the same repository call as the log sheet, and
// applies each request id once.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/wear/data/wear_bridge.dart';
import 'package:gymfy/features/wear/data/wear_sync.dart';
import 'package:gymfy/features/workout/data/next_set.dart';
import 'package:gymfy/features/workout/data/rest_timer_controller.dart';
import 'package:gymfy/features/workout/data/rest_timer_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
// RestTimer is also a Drift row class in here — the controller is the one
// this test means.
import 'package:gymfy/shared/database/app_database.dart' hide RestTimer;
import 'package:gymfy/shared/utils/units.dart';

/// Keeps the command handler so the test can play the watch.
class _FakeBridge implements WearBridge {
  Future<void> Function(String command)? handler;

  @override
  void listen(Future<void> Function(String command)? onCommand) =>
      handler = onCommand;

  @override
  Future<void> push(WearWorkout workout) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Which rests started, and how long.
final _rests = <({String exerciseId, int seconds})>[];

class _SpyTimer extends RestTimer {
  @override
  RestTimerState? build() => null;

  @override
  Future<void> start({
    required String exerciseId,
    required String exerciseName,
    required int seconds,
  }) async => _rests.add((exerciseId: exerciseId, seconds: seconds));
}

Exercise _exercise(String id, {bool timed = false}) => Exercise(
  id: id,
  name: id,
  muscleIds: const ['chest'],
  isPlateLoaded: false,
  isCustom: false,
  isArchived: false,
  isTimed: timed,
  equipment: 'barbell',
);

String _log({
  required String id,
  String exerciseId = 'bench',
  double weight = 80,
  WeightUnit unit = WeightUnit.kg,
  int? reps = 8,
  int? seconds,
}) => WearBridge.logSetCommand(
  id: id,
  exerciseId: exerciseId,
  weight: weight,
  unit: unit,
  reps: seconds == null ? reps : null,
  seconds: seconds,
);

void main() {
  group('the wire format', () {
    test('round-trips through the command string', () {
      final command = _log(id: 'a', weight: 82.5, reps: 6);
      expect(command, startsWith('${WearBridge.commandLogSet}:'));

      final request = WearBridge.parseLogSet(
        command.substring(WearBridge.commandLogSet.length + 1),
      );
      expect(request?.id, 'a');
      expect(request?.exerciseId, 'bench');
      expect(request?.weight, 82.5);
      expect(request?.unit, WeightUnit.kg);
      expect(request?.reps, 6);
      expect(request?.seconds, isNull);
    });

    test('accepts a whole weight written without a decimal point', () {
      // Android's JSONObject writes 80.0 as "80".
      final request = WearBridge.parseLogSet(
        '{"id":"a","exerciseId":"bench","weight":80,"unit":"lbs","reps":5}',
      );

      expect(request?.weight, 80);
      expect(request?.unit, WeightUnit.lbs);
    });

    test('keeps a colon inside an exercise id intact', () {
      // Custom exercise ids are the user's own text.
      final command = _log(id: 'a', exerciseId: 'my:press');
      final argument = command.substring(command.indexOf(':') + 1);

      expect(WearBridge.parseLogSet(argument)?.exerciseId, 'my:press');
    });

    test('refuses anything malformed rather than guessing', () {
      for (final bad in [
        'not json',
        '[]',
        '{"exerciseId":"bench","weight":80,"unit":"kg","reps":8}',
        '{"id":"","exerciseId":"bench","weight":80,"unit":"kg","reps":8}',
        '{"id":"a","weight":80,"unit":"kg","reps":8}',
        '{"id":"a","exerciseId":"bench","unit":"kg","reps":8}',
        '{"id":"a","exerciseId":"bench","weight":"80","unit":"kg","reps":8}',
        // An unknown unit is not kilograms: a pound weight read as kg would
        // be stored 2.2 times too heavy.
        '{"id":"a","exerciseId":"bench","weight":80,"unit":"stone","reps":8}',
        '{"id":"a","exerciseId":"bench","weight":80,"reps":8}',
        // Both, or neither, of reps and seconds.
        '{"id":"a","exerciseId":"bench","weight":80,"unit":"kg","reps":8,"seconds":30}',
        '{"id":"a","exerciseId":"bench","weight":80,"unit":"kg"}',
        '{"id":"a","exerciseId":"bench","weight":80,"unit":"kg","reps":8.5}',
      ]) {
        expect(WearBridge.parseLogSet(bad), isNull, reason: bad);
      }
    });
  });

  group('checking a request against the exercise', () {
    RemoteSetRequest request({
      double weight = 80,
      WeightUnit unit = WeightUnit.kg,
      int? reps = 8,
      int? seconds,
    }) => (
      id: 'a',
      exerciseId: 'bench',
      weight: weight,
      unit: unit,
      reps: reps,
      seconds: seconds,
    );

    test('passes a sensible set through, in kilograms', () {
      expect(validateRemoteSet(request(), _exercise('bench')), (
        weightKg: 80.0,
        reps: 8,
        seconds: null,
      ));
    });

    test('converts pounds the way the log sheet does', () {
      final set = validateRemoteSet(
        request(weight: 225, unit: WeightUnit.lbs),
        _exercise('bench'),
      );

      expect(set?.weightKg, weightToKilograms(225, WeightUnit.lbs));
    });

    test('takes a hold for a timed exercise, with no reps', () {
      final set = validateRemoteSet(
        request(weight: 0, reps: null, seconds: 60),
        _exercise('plank', timed: true),
      );

      expect(set, (weightKg: 0.0, reps: 0, seconds: 60));
    });

    test('refuses reps for a plank and a hold for a bench press', () {
      expect(
        validateRemoteSet(request(), _exercise('plank', timed: true)),
        isNull,
      );
      expect(
        validateRemoteSet(request(reps: null, seconds: 30), _exercise('bench')),
        isNull,
      );
    });

    test('refuses numbers the log sheet could not have produced', () {
      // Refused, not clamped: a clamped set is still a set nobody did.
      final bench = _exercise('bench');
      expect(validateRemoteSet(request(weight: -2.5), bench), isNull);
      expect(validateRemoteSet(request(weight: double.nan), bench), isNull);
      expect(validateRemoteSet(request(weight: 10000), bench), isNull);
      expect(validateRemoteSet(request(reps: 0), bench), isNull);
      expect(validateRemoteSet(request(reps: 100), bench), isNull);
      final plank = _exercise('plank', timed: true);
      expect(validateRemoteSet(request(reps: null, seconds: 0), plank), isNull);
      expect(
        validateRemoteSet(request(reps: null, seconds: 6000), plank),
        isNull,
      );
    });

    test('allows an empty bar', () {
      expect(
        validateRemoteSet(request(weight: 0), _exercise('bench')),
        isNotNull,
      );
    });
  });

  group('what the watch is told about the next set', () {
    final session = WorkoutSession(
      id: 1,
      name: 'Push A',
      startedAt: DateTime(2026, 10, 1, 18),
    );
    final now = DateTime(2026, 10, 1, 18, 30);
    const next = (
      exerciseId: 'bench',
      exerciseName: 'Bench Press',
      setNumber: 2,
      plannedSets: 3,
      weightKg: 80.0,
      reps: 8,
      seconds: null,
      confident: true,
    );

    test('carries the exercise, the set and the numbers', () {
      final payload = wearWorkoutFrom(
        session: session,
        rest: null,
        loggedSets: 1,
        now: now,
        next: next,
      );

      expect(payload.nextExercise, 'Bench Press');
      expect(payload.nextExerciseId, 'bench');
      expect(payload.nextSet, 'Set 2 of 3');
      expect(payload.nextWeight, 80);
      expect(payload.nextReps, 8);
      expect(payload.nextTimed, isFalse);
      expect(payload.weightUnit, 'kg');
      expect(payload.weightStep, 2.5);
    });

    test('converts for a pounds user, on a loadable step', () {
      // The watch never converts; it gets the number it should draw.
      final payload = wearWorkoutFrom(
        session: session,
        rest: null,
        loggedSets: 1,
        now: now,
        next: next,
        unit: WeightUnit.lbs,
      );

      expect(payload.weightUnit, 'lbs');
      expect(payload.nextWeight, 176);
      expect(payload.weightStep, 5);
    });

    test('says when the number is a hold', () {
      final payload = wearWorkoutFrom(
        session: session,
        rest: null,
        loggedSets: 0,
        now: now,
        next: (
          exerciseId: 'plank',
          exerciseName: 'Plank',
          setNumber: 1,
          plannedSets: 3,
          weightKg: 0.0,
          reps: 0,
          seconds: 45,
          confident: true,
        ),
      );

      expect(payload.nextTimed, isTrue);
      expect(payload.nextReps, 45);
    });

    test('offers nothing to log with nothing to log', () {
      final payload = wearWorkoutFrom(
        session: session,
        rest: null,
        loggedSets: 0,
        now: now,
      );

      expect(payload.nextExercise, isEmpty);
      expect(payload.weightUnit, isEmpty);
    });

    test('and a changed suggestion is a changed payload', () {
      // WearSync only pushes on change — a new suggestion has to count.
      WearWorkout build(double weight) => wearWorkoutFrom(
        session: session,
        rest: null,
        loggedSets: 1,
        now: now,
        next: (
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          setNumber: 2,
          plannedSets: 3,
          weightKg: weight,
          reps: 8,
          seconds: null,
          confident: true,
        ),
      );

      expect(build(80), build(80));
      expect(build(80), isNot(build(82.5)));
    });
  });

  group('the phone logging it', () {
    late AppDatabase db;
    late SessionRepository sessions;
    late int sessionId;
    late ProviderContainer container;
    late _FakeBridge bridge;

    setUp(() async {
      _rests.clear();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      sessions = SessionRepository(db);
      final plans = WorkoutRepository(db);
      for (final (id, timed) in [
        ('bench', false),
        ('row', false),
        ('curl', false),
        ('plank', true),
        ('squat', false),
      ]) {
        await db
            .into(db.exercises)
            .insert(
              ExercisesCompanion.insert(
                id: id,
                name: id,
                muscleIds: const ['chest'],
                isTimed: Value(timed),
              ),
            );
      }
      final dayId = await plans.createDay(await plans.createSplit('PPL'), 'A');
      // Bench and row are a superset; curl and plank stand alone. Squat is
      // in the library but not in this workout.
      await plans.addExercisesToDay(dayId, ['bench', 'row', 'curl', 'plank']);
      final first = (await plans.watchDayExercises(dayId).first).first;
      await plans.supersetWithNext(first.entry.id);
      sessionId = await sessions.startSession(dayId: dayId, name: 'A');

      bridge = _FakeBridge();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          wearBridgeProvider.overrideWithValue(bridge),
          restTimerProvider.overrideWith(_SpyTimer.new),
        ],
      );
      // What the phone keeps watching while a workout runs.
      container.listen(inProgressSessionProvider, (_, _) {});
      container.listen(sessionSetsProvider(sessionId), (_, _) {});
      container.listen(pickedExerciseProvider(sessionId), (_, _) {});
      container.read(wearCommandsProvider);
      await container.read(inProgressSessionProvider.future);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<List<LoggedSet>> logged() =>
        sessions.watchSessionSets(sessionId).first;

    test('writes the set with the numbers sent, and starts the rest', () async {
      // Awaited: the handler's future is what the notification's broadcast
      // waits on, so it must not complete before the set is written.
      await bridge.handler!(
        _log(id: 'a', exerciseId: 'curl', weight: 30, reps: 12),
      );

      final sets = await logged();
      expect(sets, hasLength(1));
      expect(sets.single.exerciseId, 'curl');
      expect(sets.single.weight, 30);
      expect(sets.single.reps, 12);
      expect(sets.single.setNumber, 1);
      expect(sets.single.type, SetType.normal);
      expect(_rests.map((r) => r.exerciseId), ['curl']);
    });

    test('numbers on from what the phone already logged', () async {
      await sessions.logSet(
        sessionId: sessionId,
        exerciseId: 'curl',
        setNumber: 1,
        weight: 30,
        reps: 12,
      );

      await bridge.handler!(_log(id: 'a', exerciseId: 'curl'));
      await bridge.handler!(_log(id: 'b', exerciseId: 'curl'));

      expect((await logged()).map((s) => s.setNumber), [1, 2, 3]);
    });

    test(
      'two sets arriving at once are numbered one after the other',
      () async {
        // The wrist and the shade at the same moment, two different ids: both
        // are real sets, and they must not both be "set 1".
        await Future.wait([
          bridge.handler!(_log(id: 'wrist', exerciseId: 'curl')),
          bridge.handler!(_log(id: 'shade', exerciseId: 'curl')),
        ]);

        expect((await logged()).map((s) => s.setNumber), [1, 2]);
      },
    );

    test('a double tap is one set', () async {
      // The same id twice — the notification's PendingIntent, or the
      // watch's button, pressed twice before the phone's answer arrives.
      final command = _log(id: 'same', exerciseId: 'curl');
      await bridge.handler!(command);
      await bridge.handler!(command);

      expect(await logged(), hasLength(1));
    });

    test('repeat and log share one memory of applied ids', () async {
      await sessions.logSet(
        sessionId: sessionId,
        exerciseId: 'curl',
        setNumber: 1,
        weight: 30,
        reps: 12,
      );
      await bridge.handler!('${WearBridge.commandRepeatSet}:x');
      await bridge.handler!(_log(id: 'x', exerciseId: 'curl'));

      expect(await logged(), hasLength(2));
    });

    test('stores pounds as kilograms', () async {
      await bridge.handler!(
        _log(id: 'a', exerciseId: 'curl', weight: 45, unit: WeightUnit.lbs),
      );

      expect(
        (await logged()).single.weight,
        closeTo(weightToKilograms(45, WeightUnit.lbs), 1e-9),
      );
    });

    test('logs a hold for a timed exercise', () async {
      await bridge.handler!(
        _log(id: 'a', exerciseId: 'plank', weight: 0, seconds: 60),
      );

      final set = (await logged()).single;
      expect(set.seconds, 60);
      expect(set.reps, 0);
    });

    test('refuses a set the exercise cannot have', () async {
      await bridge.handler!(_log(id: 'a', exerciseId: 'plank', reps: 10));
      await bridge.handler!(_log(id: 'b', exerciseId: 'curl', reps: 0));

      expect(await logged(), isEmpty);
      expect(_rests, isEmpty);
    });

    test('refuses an exercise that is not in the workout', () async {
      // The watch still showing something that was removed or swapped away.
      await bridge.handler!(_log(id: 'a', exerciseId: 'squat'));

      expect(await logged(), isEmpty);
    });

    test('does nothing once the workout is finished', () async {
      await sessions.completeSession(sessionId);
      await container.read(inProgressSessionProvider.future);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        if (container.read(inProgressSessionProvider).value == null) break;
      }

      await bridge.handler!(_log(id: 'a', exerciseId: 'curl'));

      expect(await logged(), isEmpty);
    });

    test('mid-superset: no rest, and the next set is the partner\'s', () async {
      await bridge.handler!(_log(id: 'a', exerciseId: 'bench'));

      expect(_rests, isEmpty);
      expect(container.read(pickedExerciseProvider(sessionId)), 'row');
    });

    test('the end of a superset round rests', () async {
      await bridge.handler!(_log(id: 'a', exerciseId: 'bench'));
      await bridge.handler!(_log(id: 'b', exerciseId: 'row'));

      expect(_rests.map((r) => r.exerciseId), ['row']);
      // And back to the top of the group for the next round.
      expect(container.read(pickedExerciseProvider(sessionId)), 'bench');
    });

    test('rests for the exercise\'s own length, not the fallback', () async {
      // Nothing is listening to the rest settings with the phone in a
      // pocket, and a provider read then answers with 90 seconds.
      await RestTimerRepository(db).setForExercise('curl', 150);

      await bridge.handler!(_log(id: 'a', exerciseId: 'curl'));

      expect(_rests.single.seconds, 150);
    });
  });
}
