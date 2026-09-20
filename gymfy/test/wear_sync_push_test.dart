// Does the watch actually get told things?
//
// wear_bridge_test covers the payload *function*. This covers the wiring —
// whether WearSync pushes, when, and how often. Those are different
// questions, and the reported bug ("the watch still thinks the workout is
// running after I finished it") lives entirely in the second one.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/wear/data/wear_bridge.dart';
import 'package:gymfy/features/wear/data/wear_sync.dart';
import 'package:gymfy/features/workout/data/rest_timer_controller.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
// RestTimer is also a Drift row class in here — the controller is the one
// this test means.
import 'package:gymfy/shared/database/app_database.dart' hide RestTimer;
import 'package:gymfy/shared/utils/units.dart';

/// Records what would have gone to the watch.
class _SpyBridge implements WearBridge {
  final pushed = <WearWorkout>[];

  @override
  Future<void> push(WearWorkout workout) async => pushed.add(workout);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

WorkoutSession _session() => WorkoutSession(
  id: 1,
  name: 'Push A',
  startedAt: DateTime(2026, 9, 20, 18),
  completedAt: null,
);

void main() {
  late _SpyBridge bridge;
  late StreamController<WorkoutSession?> sessions;

  setUp(() {
    bridge = _SpyBridge();
    sessions = StreamController<WorkoutSession?>.broadcast();
  });

  tearDown(() => sessions.close());

  ProviderContainer containerWith() => ProviderContainer(
    overrides: [
      wearBridgeProvider.overrideWithValue(bridge),
      inProgressSessionProvider.overrideWith((ref) => sessions.stream),
      sessionSetsProvider.overrideWith((ref, id) => Stream.value(const [])),
      restTimerProvider.overrideWith(_NoTimer.new),
      // The payload now carries a formatted last set, which needs the
      // display unit — and that reaches for settings in the database.
      weightUnitProvider.overrideWithValue(WeightUnit.kg),
    ],
  );

  test('finishing a workout pushes an idle payload', () async {
    final container = containerWith();
    addTearDown(container.dispose);

    // Keep it alive the way main.dart does — nothing reads the value, the
    // provider exists for the push.
    container.listen(wearSyncProvider, (_, _) {});

    sessions.add(_session());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      bridge.pushed.last.active,
      isTrue,
      reason: 'a started workout should reach the watch',
    );

    // The session ending is the whole case: watchInProgressSession emits
    // null once completedAt is set.
    sessions.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      bridge.pushed.last,
      idleWearWorkout,
      reason: 'the watch was left showing a finished workout as ongoing — '
          'without this push it keeps the last state it was ever told',
    );
  });

  test('and an unchanged state is not pushed twice', () async {
    final container = containerWith();
    addTearDown(container.dispose);
    container.listen(wearSyncProvider, (_, _) {});

    sessions.add(_session());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final afterFirst = bridge.pushed.length;

    // Same session again — the stream re-emitting does not mean anything
    // changed.
    sessions.add(_session());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bridge.pushed.length, afterFirst);
  });
}

class _NoTimer extends RestTimer {
  @override
  RestTimerState? build() => null;
}
