// A set repeated from the watch, inside a superset.
//
// On the phone, a set of anything but the last exercise of a superset starts
// no rest — you go straight to the next one. A set logged from the wrist has
// to behave the same, or the watch would start a countdown halfway through a
// superset.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/wear/data/wear_bridge.dart';
import 'package:gymfy/features/wear/data/wear_sync.dart';
import 'package:gymfy/features/workout/data/rest_timer_controller.dart';
import 'package:gymfy/features/workout/data/rest_timer_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
// RestTimer is also a Drift row class in here — the controller is the one
// this test means.
import 'package:gymfy/shared/database/app_database.dart' hide RestTimer;

/// Keeps the command handler so the test can play the watch.
class _FakeBridge implements WearBridge {
  void Function(String command)? handler;

  @override
  void listen(void Function(String command)? onCommand) => handler = onCommand;

  @override
  Future<void> push(WearWorkout workout) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Which exercises started a rest.
final _restStarts = <String>[];

class _SpyTimer extends RestTimer {
  @override
  RestTimerState? build() => null;

  @override
  Future<void> start({
    required String exerciseId,
    required String exerciseName,
    required int seconds,
  }) async => _restStarts.add(exerciseId);
}

void main() {
  late AppDatabase db;
  late SessionRepository sessions;
  late int sessionId;
  late ProviderContainer container;
  late _FakeBridge bridge;

  setUp(() async {
    _restStarts.clear();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessions = SessionRepository(db);
    final plans = WorkoutRepository(db);
    for (final id in ['bench', 'row', 'curl']) {
      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: id,
              name: id,
              muscleIds: const ['chest'],
            ),
          );
    }
    final dayId = await plans.createDay(await plans.createSplit('PPL'), 'Push');
    await plans.addExercisesToDay(dayId, ['bench', 'row', 'curl']);
    // Bench and row are a superset; the curl stands alone.
    final first = (await plans.watchDayExercises(dayId).first).first;
    await plans.supersetWithNext(first.entry.id);
    sessionId = await sessions.startSession(dayId: dayId, name: 'Push');

    bridge = _FakeBridge();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        wearBridgeProvider.overrideWithValue(bridge),
        restTimerProvider.overrideWith(_SpyTimer.new),
        restForExerciseProvider.overrideWith((ref, id) => 90),
      ],
    );
    // What the phone keeps watching while a workout runs, so the command
    // handler finds the session and its sets already loaded.
    container.listen(inProgressSessionProvider, (_, _) {});
    container.listen(sessionSetsProvider(sessionId), (_, _) {});
    // Nothing listens to the exercises themselves: with the phone in a
    // pocket nothing would, and the rest must still start.
    container.read(wearCommandsProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Logs one working set of [exerciseId] on the phone.
  Future<void> logOnPhone(String exerciseId) async {
    await sessions.logSet(
      sessionId: sessionId,
      exerciseId: exerciseId,
      setNumber: 1,
      weight: 60,
      reps: 8,
    );
  }

  /// Presses "repeat" on the watch and waits for the set to land.
  Future<void> repeatFromWatch(String id) async {
    await container.read(inProgressSessionProvider.future);
    final before = (await sessions.watchSessionSets(sessionId).first).length;
    bridge.handler!('${WearBridge.commandRepeatSet}:$id');
    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final now = (await sessions.watchSessionSets(sessionId).first).length;
      if (now > before) break;
    }
    // Room for the rest decision that follows the write.
    for (var i = 0; i < 30 && _restStarts.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test('a repeat mid-superset logs the set but starts no rest', () async {
    await logOnPhone('bench');
    await container.read(sessionSetsProvider(sessionId).future);

    await repeatFromWatch('a');

    final sets = await sessions.watchSessionSets(sessionId).first;
    expect(sets.map((s) => s.exerciseId), ['bench', 'bench']);
    expect(_restStarts, isEmpty);
  });

  test('a repeat of the last exercise of a superset rests', () async {
    await logOnPhone('row');

    await repeatFromWatch('b');

    expect(_restStarts, ['row']);
  });

  test('a standalone exercise rests as it always did', () async {
    await logOnPhone('curl');

    await repeatFromWatch('c');

    expect(_restStarts, ['curl']);
  });
}
